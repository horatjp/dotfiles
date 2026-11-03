/**
 * dotfiles/pi/extensions/opencode-go-usage.ts
 * OpenCode Go の5時間・週・月の残り枠を Pi の下部ステータスに表示する。
 * Console を開かず残り枠を把握するため、公式資料にない usage 入口を使う。
 * この入口と応答形式は変更され得る。
 * 各窓を個別に読み、壊れた窓は ?、3窓とも壊れたときだけ取得失敗とする。
 * 窓ごとに残量の色と電池を付け、週だけ復帰目安を表示。古い場合は (stale) だけ黄。名前とアイコンは紫(openrouter と同じ)、表示と通知は英語。
 * 窓間は空白2つ。管理キーを持つ openrouter が有効なときだけ、Go 側の末尾に灰色の「 │」を付ける。
 * キーは Pi 本体も同じ環境変数を使うので消さない（子プロセスに渡る）。
 */
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS = "opencode-go-usage";
const INTERVAL_MS = 5 * 60_000;
const MIN_REFRESH_MS = 60_000;
const TIMEOUT_MS = 10_000;
const OPENROUTER_ACTIVE = Symbol.for("dotfiles.openrouter-credits.active");
const processState = globalThis as typeof globalThis & { [OPENROUTER_ACTIVE]?: boolean };

// 読み込み順や /reload による変更を反映するため、表示を組み立てるたびに旗を見る。
function separator(): string {
	return processState[OPENROUTER_ACTIVE] ? ` ${paint("107;111;120", "│")}` : "";
}

export type UsageWindow = { status: unknown; percent: number; resetsAt?: unknown } | null;
export type GoUsage = { rolling: UsageWindow; weekly: UsageWindow; monthly: UsageWindow };

function readWindow(value: unknown): UsageWindow {
	const window = value as { status?: unknown; percent?: unknown; resetsAt?: unknown } | null;
	const status = window?.status;
	// 制限中は percent の欠落や異常値にかかわらず使い切りとして表示する。
	if (status === "rate-limited") return { status, percent: 100, resetsAt: window?.resetsAt };
	const percent = window?.percent;
	if (typeof percent !== "number" || !Number.isFinite(percent) || percent < 0 || percent > 100) {
		return null;
	}
	return { status, percent, resetsAt: window?.resetsAt };
}

export function readUsage(response: unknown): GoUsage {
	const usage = (response as { usage?: Partial<Record<keyof GoUsage, unknown>> } | null)?.usage;
	const result = {
		rolling: readWindow(usage?.rolling),
		weekly: readWindow(usage?.weekly),
		monthly: readWindow(usage?.monthly),
	};
	if (Object.values(result).every(window => window === null)) {
		throw new Error("invalid response");
	}
	return result;
}

// Claude と同じく、残量を丸めた整数を数字・電池・色すべてに使う。
export function remaining(window: NonNullable<UsageWindow>): number {
	return window.status === "rate-limited" ? 0 : Math.max(0, Math.min(100, Math.round(100 - window.percent)));
}

export function battery(value: number): string {
	return ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.floor(value / 10 + 0.5)];
}

export function remainingColor(value: number): string {
	return value > 50 ? "107;131;96" : value >= 20 ? "168;157;118" : "200;96;90";
}

export function resetEstimate(resetsAt: unknown, now: number): string | undefined {
	// ISO 日時だけを受け付け、Date.parse が補正する存在しない日付も除く。
	if (typeof resetsAt !== "string" ||
		!/^\d{4}-\d{2}-\d{2}T(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d+)?(?:Z|[+-](?:[01]\d|2[0-3]):[0-5]\d)$/.test(resetsAt)) return;
	const date = new Date(`${resetsAt.slice(0, 10)}T00:00:00Z`);
	if (!Number.isFinite(date.getTime()) || date.toISOString().slice(0, 10) !== resetsAt.slice(0, 10)) return;
	const reset = Date.parse(resetsAt);
	if (!Number.isFinite(reset) || reset < 0 || reset > 253402300799000 || !Number.isFinite(now)) return;
	// 分を切り上げた後に単位を選び、~60m / ~24h は繰り上げる。
	const minutes = Math.ceil(Math.max(0, reset - now) / 60_000);
	if (minutes > 1380) return `~${Math.ceil(minutes / 1440)}d`;
	if (minutes >= 60) return `~${Math.ceil(minutes / 60)}h`;
	return `~${minutes}m`;
}

export function paint(color: string, text: string): string {
	return `\x1b[38;2;${color}m${text}\x1b[0m`;
}

export function formatUsage(usage: GoUsage, now: number): string {
	const format = (label: string, window: UsageWindow) => {
		if (!window) return paint("168;157;118", `${label} ?`);
		const value = remaining(window);
		const estimate = label === "7d" ? resetEstimate(window.resetsAt, now) : undefined;
		return paint(remainingColor(value), `${label} ${battery(value)} ${value}%${estimate ? ` (${estimate})` : ""}`);
	};
	// Pi 1.5.0 は連続空白を圧縮するが SGR は保持するため、リセットを挟んで空白2つを保つ。
	return `${paint("150;135;190", "󰅴 Go")} ` + [format("5h", usage.rolling), format("7d", usage.weekly),
		format("mo", usage.monthly)].join(" \x1b[0m ");
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

	const refresh = async (ctx: ExtensionContext) => {
		if (closed || active || !ctx.hasUI) return;
		lastAttempt = Date.now();
		const currentGeneration = generation;
		const controller = new AbortController();
		active = controller;
		// 例外や応答本文には秘密が混ざり得るので、表示する理由は固定文と状態コードに限定する。
		let reason = "network error";
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
						reason = Number.isInteger(response.status) ? `HTTP ${response.status}` : "HTTP error";
						throw new Error("usage request failed");
					}
					reason = "invalid response";
					const body = await response.json();
					reason = "invalid response";
					return readUsage(body);
				})(),
				new Promise<never>((_, reject) => {
					timeout = setTimeout(() => {
						reason = "timeout";
						controller.abort();
						reject(new Error("usage request timed out"));
					}, TIMEOUT_MS);
				}),
			]);
			if (!closed && generation === currentGeneration && ctx.hasUI) {
				lastSuccess = formatUsage(usage, Date.now());
				notified = false;
				// Pi 1.5.0 はキー名順なので opencode-go-usage → openrouter-credits。
				ctx.ui.setStatus(STATUS, lastSuccess + separator());
			}
		} catch {
			if (closed || generation !== currentGeneration || !ctx.hasUI) return;
			try {
				ctx.ui.setStatus(STATUS, (lastSuccess
					? `${lastSuccess} ${paint("168;157;118", "(stale)")}`
					: `${paint("150;135;190", "󰅴 Go")} ${paint("168;157;118", "usage unavailable")}`) + separator());
				if (!notified) {
					notified = true;
					ctx.ui.notify(`Go usage unavailable (${reason})`, "warning");
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
