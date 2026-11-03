/**
 * dotfiles/pi/extensions/openrouter-credits.ts
 * OpenRouter の入金合計から使用合計を引いた残高を Pi の下部に英語で表示する。
 * 名前とアイコンは紫、金額は小数2桁に丸めた表示値で緑・黄・赤の24bit ANSI。
 * 管理キーを持って動く間だけ共有の旗を立て、Go が末尾に「 │」を付ける。Go 非表示時は単独表示。
 * 取得失敗は黄で表示し、通知の理由は英語の固定文に限定する。
 * キーの利用上限の残りと混同しないため、管理用の credits API を使う。
 * install.sh で ~/.pi/agent/extensions にディレクトリごとリンクされる。
 */
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

// /reload のモジュール再評価をまたいで保持し、子プロセスに渡る環境変数からは取り除く。
const MANAGEMENT_KEY = Symbol.for("dotfiles.openrouter-credits.managementKey");
const ACTIVE = Symbol.for("dotfiles.openrouter-credits.active");
const processState = globalThis as typeof globalThis & { [MANAGEMENT_KEY]?: string; [ACTIVE]?: boolean };
const managementKey = (processState[MANAGEMENT_KEY] ??= process.env.OPENROUTER_MANAGEMENT_KEY);
delete process.env.OPENROUTER_MANAGEMENT_KEY;

const STATUS = "openrouter-credits";
const INTERVAL_MS = 5 * 60_000;
const MIN_REFRESH_MS = 60_000;
const TIMEOUT_MS = 10_000;
// 表示と同じ小数2桁に丸めた残高の色分け(ドル)。10ドル未満は黄、3ドル未満は赤、それ以外は緑。
const WARN_BELOW = 10;
const ERROR_BELOW = 3;

export function balanceColor(balance: number): string {
	// 金額表示の絶対値・toFixed と揃え、2.996 → $3.00、9.996 → $10.00 の色を一致させる。
	balance = Number(Math.abs(balance).toFixed(2)) * Math.sign(balance);
	if (balance < ERROR_BELOW) return "200;96;90";
	if (balance < WARN_BELOW) return "168;157;118";
	return "107;131;96";
}

export function readBalance(response: unknown): number {
	const data = (response as { data?: { total_credits?: unknown; total_usage?: unknown } } | null)?.data;
	const credits = data?.total_credits;
	const usage = data?.total_usage;
	if (typeof credits !== "number" || !Number.isFinite(credits) ||
		typeof usage !== "number" || !Number.isFinite(usage) || !Number.isFinite(credits - usage)) {
		throw new Error("invalid response");
	}
	return credits - usage;
}

function paint(color: string, text: string): string {
	return `\x1b[38;2;${color}m${text}\x1b[0m`;
}

export function formatCredits(balance: number): string {
	const amount = Math.abs(balance).toFixed(2);
	return `${paint("150;135;190", "󰛳 openrouter")} ${paint(balanceColor(balance),
		`${balance < 0 && Number(amount) !== 0 ? "-" : ""}$${amount}`)}`;
}

export default function (pi: ExtensionAPI) {
	if (!managementKey) return;
	processState[ACTIVE] = true;
	let timer: ReturnType<typeof setInterval> | undefined;
	let active: AbortController | undefined;
	let generation = 0;
	let closed = true;
	let lastAttempt = 0;
	let notified = false;

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
			const balance = await Promise.race([
				(async () => {
					const response = await fetch("https://openrouter.ai/api/v1/credits", {
						headers: { Authorization: `Bearer ${managementKey}` },
						signal: controller.signal,
						redirect: "error",
					});
					if (!response.ok) {
						reason = Number.isInteger(response.status) ? `HTTP ${response.status}` : "HTTP error";
						throw new Error("credits request failed");
					}
					reason = "invalid response";
					const body = await response.json();
					reason = "invalid response";
					return readBalance(body);
				})(),
				new Promise<never>((_, reject) => {
					timeout = setTimeout(() => {
						reason = "timeout";
						controller.abort();
						reject(new Error("credits request timed out"));
					}, TIMEOUT_MS);
				}),
			]);
			if (!closed && generation === currentGeneration && ctx.hasUI) {
				ctx.ui.setStatus(STATUS, formatCredits(balance));
			}
		} catch {
			if (closed || generation !== currentGeneration || !ctx.hasUI) return;
			try {
				ctx.ui.setStatus(STATUS, `${paint("150;135;190", "󰛳 openrouter")} ${paint("168;157;118", "unavailable")}`);
				if (!notified) {
					notified = true;
					ctx.ui.notify(`openrouter unavailable (${reason})`, "warning");
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
		// /reload は旧拡張の session_shutdown を呼ぶ。外された拡張の旗をキーと違って残さない。
		delete processState[ACTIVE];
		closed = true;
		generation++;
		clearInterval(timer);
		timer = undefined;
		active?.abort();
		active = undefined;
	};

	pi.on("session_start", (_event, ctx) => {
		stop();
		if (!ctx.hasUI) return;
		processState[ACTIVE] = true;
		closed = false;
		notified = false;
		timer = setInterval(() => { void refresh(ctx); }, INTERVAL_MS);
		timer.unref();
		void refresh(ctx);
	});
	pi.on("agent_end", (_event, ctx) => {
		if (Date.now() - lastAttempt >= MIN_REFRESH_MS) void refresh(ctx);
	});
	pi.on("session_shutdown", () => { stop(); });
}
