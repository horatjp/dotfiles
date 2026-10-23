/**
 * dotfiles/pi/extensions/openrouter-credits.ts
 * OpenRouter の入金合計から使用合計を引いた残高を表示する。
 * キーの利用上限の残りと混同しないため、管理用の credits API を使う。
 * install.sh で ~/.pi/agent/extensions にディレクトリごとリンクされる。
 */
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

// /reload のモジュール再評価をまたいで保持し、子プロセスに渡る環境変数からは取り除く。
const MANAGEMENT_KEY = Symbol.for("dotfiles.openrouter-credits.managementKey");
const processState = globalThis as typeof globalThis & { [MANAGEMENT_KEY]?: string };
const managementKey = (processState[MANAGEMENT_KEY] ??= process.env.OPENROUTER_MANAGEMENT_KEY);
delete process.env.OPENROUTER_MANAGEMENT_KEY;

const STATUS = "openrouter-credits";
const INTERVAL_MS = 5 * 60_000;
const MIN_REFRESH_MS = 60_000;
const TIMEOUT_MS = 10_000;

export function formatCredits(response: unknown): string {
	const data = (response as { data?: { total_credits?: unknown; total_usage?: unknown } } | null)?.data;
	const credits = data?.total_credits;
	const usage = data?.total_usage;
	if (typeof credits !== "number" || !Number.isFinite(credits) ||
		typeof usage !== "number" || !Number.isFinite(usage) || !Number.isFinite(credits - usage)) {
		throw new Error("残高の応答形式が不正");
	}
	const balance = credits - usage;
	const amount = Math.abs(balance).toFixed(2);
	return `openrouter 残高 ${balance < 0 && Number(amount) !== 0 ? "-" : ""}$${amount}`;
}

export default function (pi: ExtensionAPI) {
	if (!managementKey) return;
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
		let reason = "通信エラー";
		let timeout: ReturnType<typeof setTimeout> | undefined;
		try {
			const status = await Promise.race([
				(async () => {
					const response = await fetch("https://openrouter.ai/api/v1/credits", {
						headers: { Authorization: `Bearer ${managementKey}` },
						signal: controller.signal,
						redirect: "error",
					});
					if (!response.ok) {
						reason = Number.isInteger(response.status) ? `HTTP ${response.status}` : "HTTP エラー";
						throw new Error("credits request failed");
					}
					reason = "応答本文の読み取り失敗";
					const body = await response.json();
					reason = "残高の応答形式が不正";
					return formatCredits(body);
				})(),
				new Promise<never>((_, reject) => {
					timeout = setTimeout(() => {
						reason = "タイムアウト";
						controller.abort();
						reject(new Error("credits request timed out"));
					}, TIMEOUT_MS);
				}),
			]);
			if (!closed && generation === currentGeneration && ctx.hasUI) ctx.ui.setStatus(STATUS, status);
		} catch {
			if (closed || generation !== currentGeneration || !ctx.hasUI) return;
			try {
				ctx.ui.setStatus(STATUS, "openrouter 残高: 取得失敗");
				if (!notified) {
					notified = true;
					ctx.ui.notify(`openrouter 残高: 取得失敗 (${reason})`, "warning");
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
	};

	pi.on("session_start", (_event, ctx) => {
		stop();
		if (!ctx.hasUI) return;
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
