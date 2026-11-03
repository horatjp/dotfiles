/**
 * dotfiles/pi/extensions/opencode-go-usage.ts
 * OpenCode Go の5時間・週・月の使用率を Pi の下部ステータスに表示する。
 * Console を開かず残り枠を把握するため、公式資料にない usage 入口を使う。
 * この入口と応答形式は変更され得る。
 * 各窓を個別に読み、壊れた窓は ?、3窓とも壊れたときだけ取得失敗とする。
 * キーは Pi 本体も同じ環境変数を使うので消さない（子プロセスに渡る）。
 */
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS = "opencode-go-usage";
const INTERVAL_MS = 5 * 60_000;
const MIN_REFRESH_MS = 60_000;
const TIMEOUT_MS = 10_000;

type UsageWindow = { status: unknown; percent: number } | null;
export type GoUsage = { rolling: UsageWindow; weekly: UsageWindow; monthly: UsageWindow };

function readWindow(value: unknown): UsageWindow {
	const window = value as { status?: unknown; percent?: unknown } | null;
	const status = window?.status;
	// 制限中は percent の欠落や異常値にかかわらず使い切りとして表示する。
	if (status === "rate-limited") return { status, percent: 100 };
	const percent = window?.percent;
	if (typeof percent !== "number" || !Number.isFinite(percent) || percent < 0 || percent > 100) {
		return null;
	}
	return { status, percent };
}

export function readUsage(response: unknown): GoUsage {
	const usage = (response as { usage?: Partial<Record<keyof GoUsage, unknown>> } | null)?.usage;
	const result = {
		rolling: readWindow(usage?.rolling),
		weekly: readWindow(usage?.weekly),
		monthly: readWindow(usage?.monthly),
	};
	if (Object.values(result).every(window => window === null)) {
		throw new Error("使用率の応答形式が不正");
	}
	return result;
}

export function usageColor(usage: GoUsage): "dim" | "warning" | "error" {
	const windows = [usage.rolling, usage.weekly, usage.monthly];
	// 表示される整数と色のしきい値を一致させる。
	const maximum = Math.max(...windows.map(window => Math.round(window?.percent ?? 0)));
	if (windows.some(window => window?.status === "rate-limited") || maximum >= 90) return "error";
	if (windows.some(window => window === null) || maximum >= 70) return "warning";
	return "dim";
}

export function formatUsage(usage: GoUsage): string {
	const format = (window: UsageWindow) => window ? `${Math.round(window.percent)}%` : "?";
	return `Go 5h ${format(usage.rolling)} 週 ${format(usage.weekly)} 月 ${format(usage.monthly)}`;
}

export default function (pi: ExtensionAPI) {
	// Pi 本体もモデル認証に使うため、環境変数は削除しない。
	const apiKey = process.env.OPENCODE_GO_API_KEY;
	if (!apiKey) return;
	let timer: ReturnType<typeof setInterval> | undefined;
	let active: AbortController | undefined;
	let generation = 0;
	let closed = true;
	let lastAttempt = 0;
	let notified = false;
	let latestCtx: ExtensionContext | undefined;
	let lastSuccess: string | undefined;
	let lastSuccessColor: ReturnType<typeof usageColor> | undefined;

	const refresh = async (ctx: ExtensionContext) => {
		if (closed || active || !ctx.hasUI) return;
		lastAttempt = Date.now();
		const currentGeneration = generation;
		const controller = new AbortController();
		active = controller;
		// 例外や応答本文には秘密が混ざり得るので、表示する理由は固定文と状態コードに限定する。
		let reason = "通信エラー";
		let timeout: ReturnType<typeof setTimeout> | undefined;
		try {
			const usage = await Promise.race([
				(async () => {
					const response = await fetch("https://opencode.ai/inference/go/v1/usage", {
						headers: { Authorization: `Bearer ${apiKey}`, Accept: "application/json" },
						signal: controller.signal,
						redirect: "error",
					});
					if (!response.ok) {
						reason = Number.isInteger(response.status) ? `HTTP ${response.status}` : "HTTP エラー";
						throw new Error("usage request failed");
					}
					reason = "応答本文の読み取り失敗";
					const body = await response.json();
					reason = "使用率の応答形式が不正";
					return readUsage(body);
				})(),
				new Promise<never>((_, reject) => {
					timeout = setTimeout(() => {
						reason = "タイムアウト";
						controller.abort();
						reject(new Error("usage request timed out"));
					}, TIMEOUT_MS);
				}),
			]);
			if (!closed && generation === currentGeneration && ctx.hasUI) {
				lastSuccess = formatUsage(usage);
				lastSuccessColor = usageColor(usage);
				notified = false;
				ctx.ui.setStatus(STATUS, ctx.ui.theme.fg(lastSuccessColor, lastSuccess));
			}
		} catch {
			if (closed || generation !== currentGeneration || !ctx.hasUI) return;
			try {
				ctx.ui.setStatus(STATUS, ctx.ui.theme.fg(lastSuccessColor === "error" ? "error" : "warning",
					lastSuccess ? `${lastSuccess} (古い)` : "Go 使用率: 取得失敗"));
				if (!notified) {
					notified = true;
					ctx.ui.notify(`Go 使用率: 取得失敗 (${reason})`, "warning");
				}
			} catch {
				// 終了と行き違って UI が無効になっても、非同期取得を未処理の reject にしない。
			}
		} finally {
			clearTimeout(timeout);
			controller.abort(); // HTTP エラー時も未読の応答本文を閉じる。
			if (active === controller) active = undefined;
		}
	};

	const stop = () => {
		closed = true;
		generation++;
		clearInterval(timer);
		timer = undefined;
		active?.abort();
		active = undefined;
		try {
			latestCtx?.ui.setStatus(STATUS, undefined);
		} catch {
			// 終了時に UI が既に無効でも、タイマー停止と取得中断は完了させる。
		}
		latestCtx = undefined;
	};

	pi.on("session_start", (_event, ctx) => {
		stop();
		latestCtx = ctx;
		if (!ctx.hasUI) return;
		closed = false;
		notified = false;
		lastSuccess = undefined;
		lastSuccessColor = undefined;
		timer = setInterval(() => { if (latestCtx) void refresh(latestCtx); }, INTERVAL_MS);
		timer.unref();
		void refresh(ctx);
	});
	pi.on("turn_end", (_event, ctx) => {
		if (closed) return;
		latestCtx = ctx;
		if (Date.now() - lastAttempt >= MIN_REFRESH_MS) void refresh(ctx);
	});
	pi.on("session_shutdown", () => { stop(); });
}
