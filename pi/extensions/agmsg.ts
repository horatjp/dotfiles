/**
 * agmsg Extension
 *
 * agmsg の受信(monitor)を Pi で行う。Pi には Claude Code の Monitor のような常駐コマンドの仕組みがないため、
 * この拡張が watch.sh を子プロセスとして常駐させ、届いたメッセージを1件ずつ会話に入れる。
 * 対象は、agmsg の Pi 用プラグイン(dotfiles/pi/agmsg)で `delivery.sh set monitor pi` したプロジェクトのみ。
 * 目印ファイルはセッション開始時とターンの終わりに確かめ直すので、join や mode の切り替えは次のターンの終わりから効く。
 *
 * dotfiles 管理 / install.sh で ~/.pi/agent/extensions にリンク
 */

import { type ChildProcess, execFile, spawn } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { createInterface, type Interface } from "node:readline";
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

export default function (pi: ExtensionAPI) {
	let watcher: ChildProcess | undefined;
	let reader: Interface | undefined;
	let watchedSession: string | undefined;
	let watchedProject: string | undefined;
	// whoami.sh が返すプロジェクトの場所。未参加なら undefined で、ターンの終わりごとに問い直す
	let project: string | undefined;
	let projectRecheckAt = 0;
	let quickExits = 0;
	let retryAt = 0;
	let syncing: Promise<void> | undefined;
	let closed = false;

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

	const stop = () => {
		// 止めた後の watch.sh が出す行を、終わったセッションへ送らないようリスナーごと外す
		reader?.close();
		reader = undefined;
		watcher?.stdout?.destroy();
		watcher?.kill("SIGTERM");
		watcher = undefined;
		watchedSession = undefined;
		watchedProject = undefined;
	};

	const start = (dir: string, sessionId: string, ctx: ExtensionContext) => {
		const startedAt = Date.now();
		let lastDiag = "";
		const child = spawn("bash", [join(SCRIPTS, "watch.sh"), sessionId, dir, "pi"], {
			stdio: ["ignore", "pipe", "pipe"],
		});
		const rl = createInterface({ input: child.stdout! });
		watcher = child;
		reader = rl;
		watchedSession = sessionId;
		watchedProject = dir;
		child.stderr!.on("data", (chunk: Buffer) => {
			lastDiag = chunk.toString().trim().split("\n").pop() ?? lastDiag;
		});
		child.on("error", (err) => {
			if (watcher === child) stop();
			notify(ctx, `agmsg: watch.sh を起動できません: ${err.message}`, "warning");
		});
		child.on("exit", (code) => {
			if (watcher !== child) return; // こちらから止めた
			stop();
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
			if (!line.trim() || reader !== rl) return;
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

	const syncOnce = async (ctx: ExtensionContext) => {
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
		// watch.sh の購読先は起動時に決まるので、セッションや登録先が替わったら張り直す
		if (watcher && (!want || watchedSession !== sessionId || watchedProject !== project)) stop();
		if (!want) quickExits = 0;
		if (want && !watcher && Date.now() >= retryAt) start(project!, sessionId, ctx);
	};

	// session_start と agent_end が重なっても、whoami を待つ間に start が二重に走らないよう1本にまとめる
	const sync = (ctx: ExtensionContext) => {
		syncing ??= syncOnce(ctx).finally(() => {
			syncing = undefined;
		});
		return syncing;
	};

	pi.on("session_start", async (_event, ctx) => {
		closed = false;
		project = undefined;
		projectRecheckAt = 0;
		quickExits = 0;
		retryAt = 0;
		await syncing;
		await sync(ctx);
	});
	pi.on("agent_end", async (_event, ctx) => {
		await sync(ctx);
	});
	pi.on("session_shutdown", async () => {
		closed = true;
		stop();
	});
}
