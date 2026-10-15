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
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const SCRIPTS = join(homedir(), ".agents/skills/agmsg/scripts");
// types/pi/type.conf の hooks_file と同じ
const MARKER = ".pi/agmsg-delivery";

export default function (pi: ExtensionAPI) {
	let watcher: ChildProcess | undefined;
	let watchedSession: string | undefined;
	// whoami.sh が返すプロジェクトの場所。未参加なら undefined で、ターンの終わりごとに問い直す
	let project: string | undefined;

	const whoami = (cwd: string) =>
		new Promise<string | undefined>((resolve) => {
			execFile("bash", [join(SCRIPTS, "whoami.sh"), cwd, "pi"], { timeout: 15_000 }, (err, stdout) => {
				if (err || !/^(agent|multiple)=/m.test(stdout)) return resolve(undefined);
				resolve(stdout.match(/ project=(.+)$/m)?.[1]);
			});
		});

	const monitorEnabled = (dir: string) => {
		try {
			return readFileSync(join(dir, MARKER), "utf8").includes("agmsg-delivery-mode: monitor");
		} catch {
			return false;
		}
	};

	const stop = () => {
		watcher?.kill("SIGTERM");
		watcher = undefined;
		watchedSession = undefined;
	};

	const start = (dir: string, sessionId: string, ctx: ExtensionContext) => {
		const child = spawn("bash", [join(SCRIPTS, "watch.sh"), sessionId, dir, "pi"], {
			stdio: ["ignore", "pipe", "ignore"],
		});
		watcher = child;
		watchedSession = sessionId;
		child.on("exit", () => {
			if (watcher === child) stop();
		});
		// watch.sh は1行1メッセージ(<ts> | <team> | <from> → <to> | <body>)で出し、出した時点で既読になる
		createInterface({ input: child.stdout! }).on("line", (line) => {
			if (!line.trim()) return;
			pi.sendMessage(
				{
					customType: "agmsg",
					content: `agmsg message received (already marked read):\n${line}\n\nHandle it per the agmsg skill; reply with send.sh if a reply is needed.`,
					display: true,
				},
				{ triggerTurn: true, deliverAs: "followUp" },
			);
		});
		if (ctx.hasUI) ctx.ui.notify("agmsg: 受信を開始しました", "info");
	};

	const sync = async (ctx: ExtensionContext) => {
		project ??= await whoami(ctx.cwd);
		const sessionId = ctx.sessionManager.getSessionId();
		const want = project !== undefined && monitorEnabled(project);
		// /new や /resume でセッションが替わったら、新しいセッション ID で張り直す
		if (watcher && (!want || watchedSession !== sessionId)) stop();
		if (want && !watcher) start(project!, sessionId, ctx);
	};

	pi.on("session_start", async (_event, ctx) => {
		project = undefined;
		await sync(ctx);
	});
	pi.on("agent_end", async (_event, ctx) => {
		await sync(ctx);
	});
	pi.on("session_shutdown", async () => {
		stop();
	});
}
