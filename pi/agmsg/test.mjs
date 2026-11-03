// Offline regression: fake Pi lifecycle + real scripts against a disposable /private/tmp store.
// Run: node pi/agmsg/test.mjs (no Pi/model, network, or production DB access).
import assert from "node:assert/strict";
import { EventEmitter } from "node:events";
import { execFileSync, spawn, spawnSync } from "node:child_process";
import { cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { stripTypeScriptTypes } from "node:module";

const here = dirname(fileURLToPath(import.meta.url));
const source = readFileSync(join(here, "../extensions/agmsg.ts"), "utf8");
const js = stripTypeScriptTypes(source).replace(/^import .*;\n/gm, "")
  .replace("export default function", "return function");
const handlers = new Map(), children = [], messages = [], notices = [], timers = new Set();
let enabled = true, registered = true, registeredMultiple = true, ownedMultiple = false;
let noisyOutput = false, invalidOutput = false;
let role, lookupFails = false, pendingLookup, lookups = 0, now = 100_000;
const execFile = (_cmd, args, options, callback) => {
  if (args[0].endsWith("whoami.sh")) {
    queueMicrotask(() => callback(null, registered ? "multiple=true project=/project" : "not_joined=true"));
  } else {
    lookups++;
    assert.equal(args[1], "active");
    assert.equal(options.timeout, 30_000);
    const finish = () => callback(lookupFails ? new Error("lookup failed") : null,
      invalidOutput ? "unexpected output\n" :
      `${noisyOutput ? "notice before\n" : ""}name=${role ?? ""}\n${noisyOutput ? "notice between\n" : ""}owned_multiple=${ownedMultiple}\nregistered_multiple=${registeredMultiple}\n${noisyOutput ? "notice after\n" : ""}`);
    if (pendingLookup) pendingLookup.finish = finish;
    else queueMicrotask(finish);
  }
};
const fakeSpawn = (_cmd, args) => {
  const child = new EventEmitter();
  child.args = args;
  child.stdout = {};
  child.stderr = new EventEmitter();
  child.signals = [];
  child.kill = (signal) => {
    child.signals.push(signal);
    child.killed = true;
    if (child.ignoreTerm && signal === "SIGTERM") return;
    if (child.holdPipe) return;
    queueMicrotask(() => { child.reader.emit("line", "now | t | lead → impl | draining"); child.emit("close", 0); });
  };
  children.push(child);
  return child;
};
const createInterface = () => {
  const reader = new EventEmitter();
  children.at(-1).reader = reader;
  return reader;
};
const fakeSetTimeout = (fn, ms) => {
  assert.ok([3_000, 60_000].includes(ms));
  const timer = { fn, ms, unref() { this.unrefed = true; } };
  timers.add(timer);
  return timer;
};
const init = new Function("execFile", "spawn", "existsSync", "readFileSync", "homedir", "dirname", "join", "createInterface", "Date", "setTimeout", "clearTimeout", js);
init(execFile, fakeSpawn, (p) => p === "/project/.pi/agmsg-delivery",
  () => enabled ? "agmsg-delivery-mode: monitor" : "off", () => "/fake-home", dirname, join, createInterface,
  { now: () => now }, fakeSetTimeout, (t) => timers.delete(t))({
  on: (event, handler) => handlers.set(event, handler), sendMessage: (message) => messages.push(message),
});
let session = "session-a";
const ctx = { cwd: "/project/subdir", hasUI: true, ui: { notify: (...args) => notices.push(args) }, sessionManager: { getSessionId: () => session } };
const fire = (event, input = {}) => handlers.get(event)(input, ctx);
const current = () => children.at(-1);
const turn = async (elapsed = 0) => { now += elapsed; await fire("agent_end"); };
const countNotice = (text) => notices.filter(([s]) => s.includes(text)).length;
const retry = async () => {
  const timer = [...timers].find((t) => t.ms === 60_000);
  assert.ok(timer?.unrefed);
  timers.delete(timer);
  timer.fn();
  await new Promise((resolve) => setImmediate(resolve));
};
await fire("session_start");
const extensionWatchArgs = [...current().args];
assert.deepEqual(extensionWatchArgs.slice(1), [session, "/project", "pi"]);
assert.equal(countNotice("役が未設定です(または外れました)"), 1);
await fire("agent_end");
assert.equal(lookups, 1); // no per-turn shell
// A real tool call 10 seconds after session_start must bypass the throttle.
role = "lead";
await fire("tool_call", { toolName: "read", input: { path: "session.sh" } });
await fire("tool_call", { toolName: "bash", input: { command: "echo unrelated" } });
await turn(10_000);
assert.equal(lookups, 1); // unrelated tools do not bypass the interval
await fire("tool_call", { toolName: "bash", input: { command: "bash /plugins/types/pi/session.sh actas /project session-a lead" } });
await turn();
assert.equal(lookups, 2);
assert.equal(children[0].killed, true);
assert.equal(messages.length, 1); // already-read stdout drained before replacement
assert.equal(current().args.at(-1), "lead");
role = "impl";
noisyOutput = true;
await fire("tool_call", { toolName: "bash", input: { command: "bash /scripts/actas-claim.sh /project pi impl session-a" } });
await turn();
assert.equal(current().args.at(-1), "impl"); // protocol lines found among unrelated lines
noisyOutput = false;
const afterClaim = lookups;
await turn();
assert.equal(lookups, afterClaim); // pending flag consumed once
role = "lead";
await fire("tool_call", { toolName: "bash", input: { command: "bash /scripts/reset.sh /project pi impl session-a" } });
await turn();
assert.equal(current().args.at(-1), "lead");
const beforeMessage = messages.length;
current().reader.emit("line", "agmsg watch: diagnostic");
assert.equal(messages.length, beforeMessage);
current().reader.emit("line", "now | t | lead → impl | task");
assert.equal(messages.length, beforeMessage + 1);
lookupFails = true;
const named = current();
await turn(30_000);
assert.ok(!named.killed);
await retry();
assert.ok(!named.killed);
assert.equal(countNotice("確認できません"), 1);
const failedLookups = lookups;
await fire("agent_end");
assert.equal(lookups, failedLookups);
lookupFails = false;
await retry();
assert.equal(timers.size, 0);
ownedMultiple = true;
await turn(30_000);
await fire("agent_end");
await turn(30_000);
assert.equal(current(), named);
assert.ok(!named.killed);
assert.equal(countNotice("役が複数あります"), 1);
ownedMultiple = false;
role = undefined;
await turn(30_000);
assert.equal(current().args.length, 4);
lookupFails = true;
await turn(30_000);
assert.equal(current().killed, true); // broad watcher is stopped on lookup failure
lookupFails = false;
role = "lead";
await retry();
current().emit("close", 1);
role = "impl";
await turn(30_000);
assert.equal(current().args.at(-1), "impl"); // changed role resets backoff
// sid change stops the old named subscription before even a failed lookup finishes.
const oldSessionWatcher = current();
lookupFails = true;
pendingLookup = {};
session = "failed-session";
const changedSession = fire("agent_end");
await new Promise((resolve) => setImmediate(resolve));
assert.ok(oldSessionWatcher.killed);
assert.deepEqual(oldSessionWatcher.signals, ["SIGTERM"]);
const beforeFailedSession = children.length;
pendingLookup.finish();
await changedSession;
assert.equal(children.length, beforeFailedSession);
lookupFails = false;
pendingLookup = undefined;
await retry();
assert.equal(current().args[1], session);
session = "session-b";
role = undefined;
await fire("agent_end"); // sid change bypasses 30 seconds
assert.equal(current().args[1], session);
assert.equal(countNotice("役が未設定です(または外れました)"), 2);
await turn(30_000);
assert.equal(countNotice("役が未設定です(または外れました)"), 2);
registeredMultiple = false;
await fire("session_start");
assert.equal(countNotice("役が未設定です(または外れました)"), 2);
enabled = false;
await fire("agent_end");
assert.equal(current().killed, true);
enabled = true;
await fire("agent_end");
assert.ok(!current().killed);
pendingLookup = {};
now += 30_000;
role = "review";
const first = fire("agent_end"), second = fire("agent_end");
await new Promise((resolve) => setImmediate(resolve));
pendingLookup.finish();
await Promise.all([first, second]);
pendingLookup = undefined;
assert.equal(current().args.at(-1), "review");
// TERM-resistant child: forward lines while waiting, then force kill at 3 seconds.
const stubborn = current();
stubborn.ignoreTerm = true;
role = "lead";
now += 30_000;
const stopping = fire("agent_end");
await new Promise((resolve) => setImmediate(resolve));
assert.deepEqual(stubborn.signals, ["SIGTERM"]);
const beforeDrain = messages.length;
stubborn.reader.emit("line", "now | t | lead → impl | waiting-for-close");
assert.equal(messages.length, beforeDrain + 1);
const stopTimer = [...timers].find((t) => t.ms === 3_000);
assert.ok(stopTimer);
timers.delete(stopTimer);
stopTimer.fn();
await stopping;
assert.deepEqual(stubborn.signals, ["SIGTERM", "SIGKILL"]);
assert.equal(current().args.at(-1), "lead");
assert.equal(timers.size, 0);
// Even if a descendant retains the pipe after KILL, stop has a bounded wait.
const heldPipe = current();
heldPipe.holdPipe = true;
role = "impl";
const heldStop = turn(30_000);
await new Promise((resolve) => setImmediate(resolve));
const heldTimer = [...timers].find((t) => t.ms === 3_000);
assert.ok(heldTimer);
timers.delete(heldTimer);
heldTimer.fn();
await heldStop;
assert.deepEqual(heldPipe.signals, ["SIGTERM", "SIGKILL"]);
heldPipe.emit("close", 0);
// Multiple ownership with no watcher must warn independently in each sid.
enabled = false;
await turn();
enabled = true;
ownedMultiple = true;
const multipleBefore = countNotice("役が複数あります");
const beforeMultiple = children.length;
session = "multi-a";
await turn();
await turn(30_000);
assert.equal(countNotice("役が複数あります"), multipleBefore + 1);
session = "multi-b";
await turn();
assert.equal(countNotice("役が複数あります"), multipleBefore + 2);
assert.equal(children.length, beforeMultiple);
ownedMultiple = false;
await turn(30_000);
// Invalid protocol is still a failed lookup; extra diagnostic lines alone are tolerated.
invalidOutput = true;
await turn(30_000);
assert.equal([...timers].filter((t) => t.ms === 60_000).length, 1);
invalidOutput = false;
await retry();
pendingLookup = {};
now += 30_000;
const duringShutdown = fire("agent_end");
await new Promise((resolve) => setImmediate(resolve));
await fire("session_shutdown");
const beforeShutdown = children.length;
lookupFails = true;
pendingLookup.finish();
await duringShutdown;
assert.equal(timers.size, 0); // failure after shutdown cannot arm a retry
lookupFails = false;
assert.equal(children.length, beforeShutdown);
pendingLookup = undefined;
registered = false;
await fire("session_start");
assert.equal(children.length, beforeShutdown);
await fire("session_shutdown");
console.log("PASS: lifecycle, 10s actas/tool hooks, noisy protocol, 30s throttle, TERM/KILL deadline and drain, sid failure isolation, multiple-role sid warnings, retry, shutdown failure");

const installed = join(process.env.HOME, ".agents/skills/agmsg/scripts");
const required = ["watch.sh", "actas-claim.sh", "join.sh", "send.sh", "lib/skill-render.sh", "skill-base.md"];
if (!required.every((f) => existsSync(join(installed, f)))) {
  console.log("SKIP (3-c): real agmsg scripts unavailable");
} else {
  const temp = mkdtempSync("/private/tmp/pi-agmsg-test-");
  const skill = join(temp, ".agents/skills/agmsg"), scripts = join(skill, "scripts");
  const live = new Set();
  try {
    cpSync(installed, scripts, { recursive: true, dereference: true });
    // Register Pi as a built-in only in this disposable installation (no plugin trust/config writes).
    cpSync(join(here, "types/pi"), join(scripts, "drivers/types/pi"), { recursive: true });
    const env = { ...process.env, HOME: temp, AGMSG_STORAGE_PATH: join(temp, "store"),
      AGMSG_CONFIG: join(temp, "config.json"), AGMSG_RESOLVE_PROJECT: "0", AGMSG_DAEMON_NOTICE_SKIP: "1",
      AGMSG_AGENT_PID: String(process.pid), AGMSG_SELF_NAME: "off", AGMSG_SELF_RENAME: "off", AGMSG_WATCH_INTERVAL: "1" };
    const run = (file, ...args) => execFileSync("bash", [join(scripts, file), ...args], { env, encoding: "utf8", timeout: 30_000 }).trim();
    const helper = (...args) => run("drivers/types/pi/session.sh", ...args);
    for (const name of ["lead", "impl"]) run("join.sh", "t", name, "pi", temp);
    assert.match(helper("active", temp, "session-a"), /registered_multiple=true/);
    assert.match(helper("actas", temp, "session-a", "lead"), /status=ok/);
    assert.match(helper("active", temp, "session-a"), /name=lead/);
    // Same process, changed sid can reclaim; old sid no longer owns it.
    assert.match(helper("actas", temp, "new-sid", "lead"), /status=ok/);
    assert.match(helper("active", temp, "session-a"), /name=\n/);
    assert.match(helper("actas", temp, "session-a", "lead"), /status=ok/);
    // Seed a real lock with a child pid, then reap the process before reclaiming it.
    const dead = spawn("sleep", ["30"]);
    const deadClosed = new Promise((r) => dead.once("close", r));
    try { assert.match(run("actas-claim.sh", temp, "pi", "impl", `dead.${dead.pid}`), /status=ok/); }
    finally { dead.kill(); await deadClosed; }
    if (spawnSync("ps", ["-p", String(process.pid), "-o", "pid="], { stdio: "ignore" }).status === 0) {
      assert.match(helper("actas", temp, "session-b", "impl"), /status=ok/);
    } else {
      // Sandbox blocks ps. Only this stale-lock case supplies a synthetic completed
      // snapshot; all claim/watch scripts and all other cases remain real.
      const result = execFileSync("bash", ["-c", `
        ps() { if [ "$*" = "-Ao pid=,stat=" ]; then printf '%s S\\n' "$$"; else command ps "$@"; fi; }
        export -f ps
        bash "$TEST_HELPER" actas "$HOME" session-b impl
      `], { env: { ...env, TEST_HELPER: join(scripts, "drivers/types/pi/session.sh") }, encoding: "utf8" });
      assert.match(result, /status=ok/);
      console.log("PASS: stale-lock reclaim with synthetic ps snapshot (host ps denied; real host liveness unconfirmed)");
    }
    assert.match(helper("active", temp, "session-b"), /name=impl/);

    const watch = (sid, name) => {
      // Same bare sid/type/project argv as the extension; real scripts normalize it independently.
      const args = [extensionWatchArgs[0].replace(/^.*\/watch.sh$/, join(scripts, "watch.sh")), sid, temp, "pi", ...(name ? [name] : [])];
      const child = spawn("perl", ["-e", "alarm 20; exec @ARGV", "bash", ...args], { env });
      const record = { child, out: "", err: "", closed: false };
      record.done = new Promise((resolve) => child.once("close", () => { record.closed = true; live.delete(record); resolve(); }));
      child.stdout.on("data", (c) => { record.out += c; });
      child.stderr.on("data", (c) => { record.err += c; });
      live.add(record);
      return record;
    };
    const waitFor = async (test, detail) => {
      const until = Date.now() + 12_000;
      while (!test() && Date.now() < until) await new Promise((r) => setTimeout(r, 50));
      assert.ok(test(), detail());
    };
    const stopWatch = async (w) => { w.child.kill("SIGTERM"); await w.done; };
    const send = (to, body) => run("send.sh", "t", "lead", to, body);
    const unread = () => execFileSync("bash", ["-c", `SKILL_DIR="$TEST_SKILL";
      source "$SKILL_DIR/scripts/lib/storage.sh"; agmsg_storage_load;
      storage_list_unread t lead; storage_list_unread t impl`],
      { env: { ...env, TEST_SKILL: skill }, encoding: "utf8", timeout: 30_000 });
    const a = watch("session-a", "lead"), b = watch("session-b", "impl");
    send("lead", "named-lead"); send("impl", "named-impl");
    await waitFor(() => a.out.includes("named-lead") && b.out.includes("named-impl"), () => JSON.stringify([a.out, a.err, b.out, b.err]));
    assert.ok(!a.closed && !b.closed); // neither sees own session.sh claim as other:
    assert.ok(!a.out.includes("named-impl") && !b.out.includes("named-lead"));
    assert.ok(!a.err.includes("cannot claim") && !b.err.includes("cannot claim"));
    await stopWatch(a); await stopWatch(b);
    // Release locks via their public API, leaving registrations intact for the broad reproduction.
    execFileSync("bash", ["-c", `SKILL_DIR="$TEST_SKILL"; source "$SKILL_DIR/scripts/lib/actas-lock.sh";
      actas_lock_release t lead "session-a.$AGMSG_AGENT_PID";
      actas_lock_release t impl "session-b.$AGMSG_AGENT_PID"`], { env: { ...env, TEST_SKILL: skill } });
    const broad = watch("broad-first");
    send("lead", "broad-lead"); send("impl", "broad-impl");
    await waitFor(() => broad.out.includes("broad-lead") && broad.out.includes("broad-impl"), () => broad.out + broad.err);
    // stdout precedes the consume transaction: wait for the public unread API,
    // otherwise killing here can interrupt mark-read and legitimately replay rows.
    await waitFor(() => !/broad-(lead|impl)/.test(unread()), () => "broad rows not consumed");
    await stopWatch(broad);
    const later = watch("broad-later");
    // Prove first consumer advanced both roles: a later consumer gets neither old message.
    send("lead", "later-ready");
    await waitFor(() => later.out.includes("later-ready"), () => broad.out + later.out + later.err);
    assert.ok(!later.out.includes("broad-lead") && !later.out.includes("broad-impl"));
    await stopWatch(later);
    // Real active lookup reports multiple ownership as data, with exit 0.
    assert.match(helper("actas", temp, "multi", "lead"), /status=ok/);
    assert.match(run("actas-claim.sh", temp, "pi", "impl", "multi"), /status=ok/);
    assert.match(helper("active", temp, "multi"), /owned_multiple=true/);
    assert.match(helper("actas", temp, "multi", "impl"), /status=ok/);
    assert.match(helper("active", temp, "multi"), /name=impl\nowned_multiple=false/);
    const rendered = join(temp, "SKILL.md");
    execFileSync("bash", ["-c", `SCRIPT_DIR="$TEST_SKILL"; source "$SCRIPT_DIR/scripts/lib/type-registry.sh";
      source "$SCRIPT_DIR/scripts/lib/skill-render.sh"; agmsg_render_skill pi agmsg "$TEST_RENDERED"`],
      { env: { ...env, TEST_SKILL: skill, TEST_RENDERED: rendered }, timeout: 30_000 });
    const text = readFileSync(rendered, "utf8");
    assert.ok(text.includes('session.sh actas "$(pwd)" "$PI_SESSION_ID" <name>'));
    assert.ok(text.includes('reset.sh "$(pwd)" pi <name> "$PI_SESSION_ID"'));
    assert.ok(text.includes("registration itself") && text.includes("Until then"));
    assert.ok(!text.includes("__AGENT_TYPE__"));
    console.log("PASS: real watch role isolation, broad first-consumer reproduction, session/watch ID agreement, stale lock, sid reclaim, skill rendering (disposable DB)");
  } finally {
    for (const w of live) w.child.kill("SIGTERM");
    await Promise.all([...live].map((w) => w.done));
    rmSync(temp, { recursive: true, force: true });
  }
}
