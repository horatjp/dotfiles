/**
 * agmsg Extension
 *
 * agmsg の受信(monitor)を Pi で行う。Pi には Claude Code の Monitor のような常駐コマンドの仕組みがないため、
 * この拡張が watch.sh を子プロセスとして常駐させ、届いたメッセージを1件ずつ会話に入れる。
 * 対象は、agmsg の Pi 用プラグイン(dotfiles/pi/agmsg)で `delivery.sh set monitor pi` したプロジェクトのみ。
 * 目印ファイルはセッション開始時とターンの終わりに確かめ直すので、join や mode の切り替えは次のターンの終わりから効く。
 *
 * 役名つきの購読・lock・反映には pi/agmsg/install.sh の再実行(SKILL の再合成)と Pi の /reload か再起動が必要。
 *
 * dotfiles 管理 / install.sh で ~/.pi/agent/extensions にリンク
 */

import { type ChildProcess, execFile, spawn } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { createInterface } from "node:readline";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const SCRIPTS = join(homedir(), ".agents/skills/agmsg/scripts");
// types/pi/type.conf の hooks_file と同じ
const MARKER = ".pi/agmsg-delivery";
// watch.sh のメッセージ行(<ts> | <team> | <from> → <to> | <body>)。
// 同じ標準出力に「agmsg watch: ...」「ERROR: ...」の診断行も出るので、これに合う行だけを会話に入れる
const MESSAGE_LINE = /^[^|]+ \| [^|]+ \| [^|]+ → [^|]+ \| /;
// 起動からこれより早く終わったら異常終了とみなし、再起動を遅らせる(診断行で終わる起動と再起動の繰り返しを防ぐ)
const QUICK_EXIT_MS = 10_000;
const MAX_BACKOFF_MS = 30 * 60_000;
// 古い目印の場所で後から join する場合も拾いつつ、bash と sqlite を毎ターン起動しないための間隔
const PROJECT_RECHECK_MS = 60_000;
const ROLE_RECHECK_MS = 30_000;
const LOOKUP_RETRY_MS = 60_000;
const STOP_TIMEOUT_MS = 3_000;

export default function (pi: ExtensionAPI) {
	let watcher: ChildProcess | undefined;
	let watchedSession: string | undefined;
	let watchedProject: string | undefined;
	let watchedName: string | undefined;
	let lastTarget: string | undefined;
	// whoami.sh が返すプロジェクトの場所。未参加なら undefined で、ターンの終わりごとに問い直す
	let project: string | undefined;
	let projectRecheckAt = 0;
	let quickExits = 0;
	let retryAt = 0;
	let syncing: Promise<void> | undefined;
	let closed = false;
	let checkedSession: string | undefined;
	let checkedAt = 0;
	let cachedName: string | undefined;
	let lookupFailed = false;
	let retryTimer: ReturnType<typeof setTimeout> | undefined;
	let roleWarningPending = true;
	let multipleWarned = false;
	let ownedMultiple = false;
	let roleCheckPending = false;

	const notify = (ctx: ExtensionContext, text: string, level: "info" | "warning") => {
		if (closed || !ctx.hasUI) return;
		try {
			ctx.ui.notify(text, level);
		} catch {
			// セッションの終了と行き違うと ctx は使えなくなる
		}
	};

	const whoami = (cwd: string) =>
		new Promise<string | undefined>((resolve) => {
			execFile("bash", [join(SCRIPTS, "whoami.sh"), cwd, "pi"], { timeout: 15_000 }, (err, stdout) => {
				if (err || !/^(agent|multiple)=/m.test(stdout)) return resolve(undefined);
				resolve(stdout.match(/ project=(.+)$/m)?.[1]);
			});
		});
	// 会話中の FROM ではなく、actas がこのセッションで取得した lock を問い合わせる。
	const activeName = (dir: string, sessionId: string) =>
		new Promise<{ name?: string; registeredMultiple: boolean; ownedMultiple: boolean }>((resolve, reject) => {
			execFile("bash", [join(SCRIPTS, "../plugins/types/pi/session.sh"), "active", dir, sessionId], { timeout: 30_000 }, (err, stdout) => {
				if (err) return reject(err);
				const name = stdout.match(/^name=(.*)$/m);
				const owned = stdout.match(/^owned_multiple=(true|false)$/m);
				const registered = stdout.match(/^registered_multiple=(true|false)$/m);
				if (!name || !owned || !registered) {
					return reject(new Error("invalid session.sh response"));
				}
				resolve({ name: name[1] || undefined,
					registeredMultiple: registered[1] === "true", ownedMultiple: owned[1] === "true" });
			});
		});

	// 目印ファイルを cwd から上へ探し、いちばん近い目印のあるディレクトリを返す。
	// 無ければ monitor の対象外なので、whoami.sh(bash と sqlite の起動)を省く
	const markerDirAbove = (cwd: string) => {
		for (let dir = cwd; ; dir = dirname(dir)) {
			if (existsSync(join(dir, MARKER))) return dir;
			if (dirname(dir) === dir) return undefined;
		}
	};

	const monitorEnabled = (dir: string) => {
		try {
			return readFileSync(join(dir, MARKER), "utf8").includes("agmsg-delivery-mode: monitor");
		} catch {
			return false;
		}
	};

	const stop = async () => {
		const child = watcher;
		if (!child) return;
		// exit では stdout の残りが届く前なので、close まで旧 reader を生かして既読行を流す。
		watcher = undefined;
		watchedSession = watchedProject = watchedName = undefined;
		await new Promise<void>((resolve) => {
			// TERM を無視した場合や子孫が pipe を保持する場合も、張り直しを無期限に止めない。
			// reader は close まで残すので、待機中の既読行も引き続き会話へ流れる。
			const timer = setTimeout(() => { child.kill("SIGKILL"); resolve(); }, STOP_TIMEOUT_MS);
			child.once("close", () => { clearTimeout(timer); resolve(); });
			child.kill("SIGTERM");
		});
	};

	const start = (dir: string, sessionId: string, name: string | undefined, ctx: ExtensionContext) => {
		const startedAt = Date.now();
		let lastDiag = "";
		const child = spawn("bash", [join(SCRIPTS, "watch.sh"), sessionId, dir, "pi", ...(name ? [name] : [])], {
			stdio: ["ignore", "pipe", "pipe"],
		});
		const rl = createInterface({ input: child.stdout! });
		watcher = child;
		watchedSession = sessionId;
		watchedProject = dir;
		watchedName = name;
		child.stderr!.on("data", (chunk: Buffer) => {
			lastDiag = chunk.toString().trim().split("\n").pop() ?? lastDiag;
		});
		child.on("error", (err) => {
			if (watcher === child) void stop();
			notify(ctx, `agmsg: watch.sh を起動できません: ${err.message}`, "warning");
		});
		child.on("close", (code) => {
			if (watcher !== child) return; // こちらから止めた
			watcher = undefined;
			if (Date.now() - startedAt < QUICK_EXIT_MS) {
				quickExits++;
				retryAt = Date.now() + Math.min(60_000 * 2 ** (quickExits - 1), MAX_BACKOFF_MS);
			} else {
				quickExits = 0;
			}
			notify(ctx, `agmsg: 受信が止まりました (exit ${code})${lastDiag ? `: ${lastDiag}` : ""}`, "warning");
		});
		// watch.sh は出した時点でメッセージを既読にする
		rl.on("line", (line) => {
			if (!line.trim()) return;
			if (!MESSAGE_LINE.test(line)) {
				lastDiag = line;
				notify(ctx, line, "warning");
				return;
			}
			try {
				pi.sendMessage(
					{
						customType: "agmsg",
						content: `agmsg message received (already marked read):\n${line}\n\nHandle it per the agmsg skill; reply with send.sh if a reply is needed.`,
						display: true,
					},
					{ triggerTurn: true, deliverAs: "followUp" },
				);
			} catch {
				// セッションの終了と行き違った。既読にはなっているので、受信箱(inbox.sh)からは見える
			}
		});
		notify(ctx, "agmsg: 受信を開始しました", "info");
	};

	const syncOnce = async (ctx: ExtensionContext, retry = false) => {
		// 目印と登録先が食い違う間は、同じ場所での join も拾えるよう間隔をあけて問い直す。
		// 未参加・照会失敗なら次のターンで再試行し、一致していれば whoami.sh を省く
		const markerDir = markerDirAbove(ctx.cwd);
		if (markerDir !== undefined && (project === undefined || (project !== markerDir && Date.now() >= projectRecheckAt))) {
			project = await whoami(ctx.cwd);
			projectRecheckAt = Date.now() + PROJECT_RECHECK_MS;
		}
		if (closed) return;
		const sessionId = ctx.sessionManager.getSessionId();
		const want = project !== undefined && monitorEnabled(project);
		if (checkedSession !== sessionId) {
			roleWarningPending = true;
			multipleWarned = false;
		}
		// 新しい会話には、照会結果を待つ間も古い会話の役の新着を受け取らせない。
		if (watcher && watchedSession !== sessionId) await stop();
		if (closed) return;
		if (want && lookupFailed && retryTimer && !retry && !roleCheckPending && checkedSession === sessionId) return;
		let name = cachedName;
		try {
			if (want && (roleCheckPending || checkedSession !== sessionId || Date.now() - checkedAt >= ROLE_RECHECK_MS || lookupFailed)) {
				roleCheckPending = false;
				const status = await activeName(project!, sessionId);
				if (closed) return;
				checkedSession = sessionId;
				checkedAt = Date.now();
				lookupFailed = false;
				clearTimeout(retryTimer);
				retryTimer = undefined;
				ownedMultiple = status.ownedMultiple;
				if (ownedMultiple) {
					if (!multipleWarned) notify(ctx, "agmsg: 役が複数あります。/skill:agmsg drop で外してください", "warning");
					multipleWarned = true;
					return; // 現在の購読を維持し、勝手に役を選ばない
				}
				multipleWarned = false;
				name = cachedName = status.name;
				if (roleWarningPending && status.registeredMultiple && !name) {
					notify(ctx, "agmsg: 役が未設定です(または外れました)。/skill:agmsg actas <名前> をしてください", "warning");
				}
				roleWarningPending = false;
			}
		} catch {
			if (closed) return;
			// 同じ会話の役名つき購読だけ維持する。lock を失えば watch.sh 自身が停止する。
			if (!lookupFailed) notify(ctx, "agmsg: Pi の役を確認できません。再試行します", "warning");
			checkedSession = sessionId;
			lookupFailed = true;
			if (!retryTimer) {
				retryTimer = setTimeout(() => { retryTimer = undefined; void sync(ctx, true); }, LOOKUP_RETRY_MS);
				retryTimer.unref();
			}
			if (!watchedName) await stop();
			return;
		}
		if (closed) return;
		if (want && ownedMultiple) return;
		const target = JSON.stringify([sessionId, project, want, name]);
		if (lastTarget !== target) {
			lastTarget = target;
			retryAt = 0;
			quickExits = 0;
		}
		// 購読先は起動時に決まるので、actas による役の変更も張り直す。
		if (watcher && (!want || watchedSession !== sessionId || watchedProject !== project || watchedName !== name)) {
			await stop();
		}
		if (!want) quickExits = 0;
		if (closed) return;
		if (want && !watcher && Date.now() >= retryAt) start(project!, sessionId, name, ctx);
	};

	// session_start と agent_end が重なっても、whoami を待つ間に start が二重に走らないよう1本にまとめる
	const sync = (ctx: ExtensionContext, retry = false) => {
		syncing ??= syncOnce(ctx, retry).finally(() => {
			syncing = undefined;
		});
		return syncing;
	};

	pi.on("session_start", async (_event, ctx) => {
		closed = false;
		checkedSession = undefined;
		roleWarningPending = true;
		multipleWarned = false;
		roleCheckPending = false;
		project = undefined;
		projectRecheckAt = 0;
		quickExits = 0;
		retryAt = 0;
		await syncing;
		await sync(ctx);
	});
	// Pi 1.5.0 の ToolCallEvent: bash のコマンドは event.input.command。
	// 成否にかかわらず再照会し、失敗した actas でも実際の lock を正とする。
	pi.on("tool_call", (event) => {
		if (event.toolName === "bash" && typeof event.input.command === "string"
			&& /session\.sh|actas-claim\.sh|reset\.sh/.test(event.input.command)) roleCheckPending = true;
	});
	pi.on("agent_end", async (_event, ctx) => {
		await syncing;
		await sync(ctx);
	});
	pi.on("session_shutdown", async () => {
		closed = true;
		clearTimeout(retryTimer);
		retryTimer = undefined;
		await stop();
	});
}
