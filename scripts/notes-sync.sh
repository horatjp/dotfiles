#!/bin/bash
# どこ: dotfiles/scripts。LaunchAgent から起動する。
# 何: notes の保存をまとめて commit/pull/push する。
# なぜ: 秘密・大容量ファイルを避け、一時障害を再試行する。
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never GIT_LITERAL_PATHSPECS=1
repo="${1:-${NOTES_SYNC_REPO:-$HOME/projects/notes}}"
debounce="${NOTES_SYNC_DEBOUNCE:-10}"
interval="${NOTES_SYNC_PULL_INTERVAL:-300}"
max_wait="${NOTES_SYNC_MAX_WAIT:-300}"
network_timeout="${NOTES_SYNC_NETWORK_TIMEOUT:-120}"
lock_age="${NOTES_SYNC_LOCK_AGE:-60}"
retries="${NOTES_SYNC_RETRIES:-3}"
retry_delay="${NOTES_SYNC_RETRY_DELAY:-2}"
maintenance_interval="${NOTES_SYNC_MAINTENANCE_INTERVAL:-30}"
for value in "$debounce" "$interval" "$max_wait" "$network_timeout" "$lock_age" "$retries" "$retry_delay" "$maintenance_interval"; do
    [[ "$value" =~ ^[1-9][0-9]*$ ]] || { echo '待ち時間・回数は正の整数が必要です' >&2; exit 1; }
done
logfile="${NOTES_SYNC_LOG:-$HOME/Library/Logs/notes-sync.log}"
mkdir -p "$(dirname "$logfile")"
cd "$repo"
[[ "$(git rev-parse --show-toplevel)" == "$(pwd -P)" ]] || exit 1
gitdir="$(git rev-parse --absolute-git-dir)"
stopfile="$gitdir/notes-sync.stopped"
# リポジトリの絶対パスを識別子にする。内容のハッシュ計算ではない。
key="$(printf '%s' "$gitdir" | shasum -a 256 | cut -d ' ' -f 1)"
lock="${TMPDIR:-/tmp}/notes-sync-$key.lock"
owner_active() {
    [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null || return 1
    local command_line
    if ! command_line="$("${NOTES_SYNC_PS:-/bin/ps}" -p "$pid" -o command= 2>/dev/null)"; then
        # 確認不能を死活不明のまま回収すると二重起動を許すため、保護する。
        kill -0 "$pid" 2>/dev/null || return 1
        printf '%s ロック所有者を確認できないため待機: pid=%s\n' "$(date)" "$pid" >> "$logfile"
        exit 1
    fi
    [[ "$command_line" == *notes-sync.sh* ]]
}
if ! mkdir "$lock" 2>/dev/null; then
    identity="$(stat -f %i "$lock")"
    pid="$(cat "$lock/pid" 2>/dev/null || true)"
    if owner_active; then exit 0; fi
    # pid 書き込み前の起動と競合しないよう、pid 不在時は猶予を置く。
    if [[ -z "$pid" ]] && ! /usr/bin/perl -e 'exit(time - (stat $ARGV[0])[9] >= $ARGV[1] ? 0 : 1)' "$lock" "$lock_age"; then exit 1; fi
    if ! mkdir "$lock/reclaim" 2>/dev/null; then
        # 回収処理自体の強制終了でも永久に詰まらないよう、古い回収印を捨てる。
        /usr/bin/perl -e 'exit(time - (stat $ARGV[0])[9] >= $ARGV[1] ? 0 : 1)' "$lock/reclaim" "$lock_age" || exit 1
        rmdir "$lock/reclaim" 2>/dev/null || exit 1
        mkdir "$lock/reclaim" 2>/dev/null || exit 1
    fi
    # 回収の競合相手がすでに新しいロックを作った場合は触らない。
    if [[ "$(stat -f %i "$lock")" != "$identity" ]]; then rmdir "$lock/reclaim"; exit 1; fi
    pid="$(cat "$lock/pid" 2>/dev/null || true)"
    if owner_active; then
        rmdir "$lock/reclaim"; exit 0
    fi
    rm -rf "$lock"
    mkdir "$lock" 2>/dev/null || exit 1
fi
printf '%s\n' "$$" > "$lock/pid"
trap 'rm -rf "$lock"' EXIT
trap 'exit 0' TERM INT HUP
# ロック取得後に回すため、二重起動でログをローテートしない。
rotate_log() {
    if [[ -f "$logfile" ]] && [[ "$(stat -f %z "$logfile")" -gt 1048576 ]]; then
        mv -f "$logfile" "$logfile.1"
        exec >>"$logfile" 2>&1
    fi
}
rotate_log
exec >>"$logfile" 2>&1
log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
notify() {
    if [[ -n "${NOTES_SYNC_NOTIFY:-}" ]]; then "$NOTES_SYNC_NOTIFY" "$1" || true
    else /usr/bin/osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title "notes-sync"' -e 'end run' "$1" || true; fi
}
halt_sync() {
    local message="$*。解決後、停止ファイル $stopfile を削除すると自動再開します"
    log "停止: $message"
    printf '%s\n' "$*" > "$stopfile"
    notify "$message"
}
check_state() {
    [[ ! -e "$stopfile" ]] || return 1
    if [[ -d "$gitdir/rebase-merge" || -d "$gitdir/rebase-apply" || -f "$gitdir/MERGE_HEAD" || -f "$gitdir/CHERRY_PICK_HEAD" ]] || [[ -n "$(git ls-files -u)" ]]; then
        halt_sync 'マージ・rebase・cherry-pick または未解決の衝突があります'; return 1
    fi
    if [[ "$(git symbolic-ref --quiet --short HEAD || true)" != main ]]; then
        if (( !branch_warned )); then log 'main 以外: main に戻るまで待機'; notify 'main 以外のため待機中。main に戻ると自動再開します'; branch_warned=1; fi
        return 1
    fi
    if (( branch_warned )); then log 'main に復帰、同期再開'; branch_warned=0; fi
}
# 全経路で同じ除外規則を使う。NUL 区切りで改行等を含む名前も保つ。
filter_paths() {
    NOTES_SYNC_LOCK="$lock" /usr/bin/perl -0ne '
        chomp; my $reason = "";
        if (m{(?:^|/)(?:\.env(?:\..*)?|id_rsa[^/]*|id_ed25519[^/]*)(?:/|$)}i || /(?:\.pem|\.key|\.p12)\z/i || /credentials/i) { $reason = "秘密候補"; }
        elsif (-f $_ && -s _ > 50*1024*1024) { $reason = "50MB超"; }
        my $noise = m{(?:^|/)(?:\.git|\.DS_Store|\.#.*|#.*#)(?:/|$)} || /(?:\.sw[a-z]|~|\.tmp|\.temp)\z/;
        if ($reason) {
            open my $f, ">>", "$ENV{NOTES_SYNC_LOCK}/rejected" or die $!;
            print $f "$reason: $_\0"; close $f;
        }
        print "$_\0" unless $reason || $noise;
    '
}
files() {
    git ls-files -z --cached --others --exclude-standard | filter_paths
}
warn_exclusions() {
    [[ -f "$lock/rejected" ]] || return 0
    local count=0 shown=0
    while IFS= read -r -d '' warning; do
        local id
        id="$(printf '%s' "$warning" | shasum -a 256 | cut -d ' ' -f 1)"
        if [[ ! -e "$lock/warn-$id" ]]; then
            touch "$lock/warn-$id"; log "add 除外: $warning"
            count=$((count + 1))
            if (( shown < 3 )); then notify "add 除外: $warning"; shown=$((shown + 1)); fi
        fi
    done < "$lock/rejected"
    if (( count > shown )); then notify "add 除外: ほか $((count - shown)) 件。詳細はログを確認してください"; fi
    : > "$lock/rejected"
}
snapshot() {
    files | /usr/bin/perl -MDigest::SHA -0e '
        my $sha = Digest::SHA->new(256);
        for my $p (sort <STDIN>) {
            chomp $p; my @s = lstat $p;
            $sha->add($p, "\0", @s ? "$s[7]:$s[9]" : "missing", "\0");
        }
        print $sha->hexdigest;
    '
}
# 子プロセス群ごと終了させ、タイムアウト後の Git/ssh を残さない。
network_git() {
    /usr/bin/perl -MPOSIX=setpgid -e '
        my $limit = shift; my $pid = fork(); defined $pid or die $!;
        if (!$pid) { setpgid(0,0); exec @ARGV; die $!; }
        sub stop_child { kill "TERM", -$pid; sleep 1; kill "KILL", -$pid; waitpid($pid,0); }
        $SIG{ALRM} = sub { stop_child(); exit 124; };
        $SIG{TERM} = $SIG{INT} = sub { stop_child(); exit 143; };
        alarm $limit; waitpid($pid,0); my $s=$?; alarm 0;
        exit($s & 127 ? 128 + ($s & 127) : $s >> 8);
    ' "$network_timeout" git -c credential.interactive=false -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=30 "$@"
}
retry_git() {
    local attempt
    for ((attempt=1; attempt<=retries; attempt++)); do
        # 消えた未追跡ファイルを古い pathspec に残さない。再試行でも再列挙する。
        if [[ "$1" == add ]]; then
            files > "$lock/paths"
            [[ -s "$lock/paths" ]] || return 0
        fi
        if git "$@"; then return 0; fi
        log "git $1 失敗: $attempt/$retries"
        if (( attempt < retries )); then sleep "$retry_delay"; fi
    done
    halt_sync "git $1 が $retries 回失敗しました"; return 1
}
pull_changes() {
    check_state || return 1
    local dirty before result=0
    dirty="$( { git diff --name-only -z; git diff --cached --name-only -z; } | filter_paths | /usr/bin/perl -0ne 'END { print "dirty" if $seen } $seen = 1')"
    if [[ -n "$dirty" ]]; then log 'pull スキップ: 同期対象に未保存の変更あり'; return 1; fi
    before="$(git rev-parse HEAD)"
    # 除外した追跡済みファイルも Git の autostash で保護する。
    network_git pull --rebase --autostash origin main > "$lock/network-output" 2>&1 || result=$?
    # autostash の復元衝突でも pull は成功扱いになり得るため、終了値によらず検査する。
    if [[ -n "$(git ls-files -u)" ]] && git stash list --format='%s' | /usr/bin/perl -ne '$seen=1 if /autostash/; END { exit !$seen }'; then
        log 'autostash 復元時の衝突: 退避した内容は stash に残っています。手動で確認してください'
        halt_sync 'pull 後に衝突があります。autostash の内容は stash に残っています'; return 1
    fi
    check_state || return 1
    if (( result == 0 )); then
        [[ "$before" == "$(git rev-parse HEAD)" ]] || log 'pull 完了: 変更あり'
    else
        cat "$lock/network-output"; log 'pull 失敗・時間切れ。次回再試行'; return 1
    fi
}
sync_changes() {
    check_state || return 0
    git diff --cached --name-only -z > "$lock/staged"
    filter_paths < "$lock/staged" > "$lock/allowed"
    cmp -s "$lock/staged" "$lock/allowed" || { halt_sync '除外対象が stage 済みです。手動で確認してください'; return 0; }
    retry_git add -A --pathspec-from-file="$lock/paths" --pathspec-file-nul || return 0
    if ! git diff --cached --quiet; then
        retry_git commit -m "notes: 自動保存 $(date '+%Y-%m-%d %H:%M:%S')" || return 0
    fi
    pull_changes || return 0
    local ahead
    ahead="$(git rev-list --count origin/main..HEAD)"
    if network_git push origin main > "$lock/network-output" 2>&1; then
        if (( ahead > 0 )); then log 'push 完了: 変更あり'; fi
        push_failures=0; push_warned=0
    else
        cat "$lock/network-output"
        push_failures=$((push_failures + 1)); log "push 失敗・時間切れ: 連続 $push_failures 回。次回再試行"
        if (( push_failures >= 3 && !push_warned )); then notify 'push が連続3回失敗しました。ログを確認してください'; push_warned=1; fi
    fi
}
branch_warned=0 push_failures=0 push_warned=0
log "起動: debounce=${debounce}s pull=${interval}s。停止ファイル削除で自動再開"
last='' changed_at=$SECONDS first_change=$SECONDS next_pull=$SECONDS pending=1 next_maintenance=$SECONDS
while :; do
    if (( SECONDS >= next_maintenance )); then
        rotate_log
        # ignored の全走査は重いため、通常の snapshot から分離する。
        git ls-files -z --others --ignored --exclude-standard | filter_paths > /dev/null
        next_maintenance=$((SECONDS + maintenance_interval))
    fi
    if ! check_state; then warn_exclusions; sleep 1; continue; fi
    current="$(snapshot)"
    warn_exclusions
    if [[ "$current" != "$last" ]]; then
        if (( !pending )); then first_change=$SECONDS; fi
        last="$current"; changed_at=$SECONDS; pending=1
    fi
    if (( pending && (SECONDS - changed_at >= debounce || SECONDS - first_change >= max_wait) )); then
        sync_changes
        pending=0; next_pull=$((SECONDS + interval))
    elif (( !pending && SECONDS >= next_pull )); then
        sync_changes; next_pull=$((SECONDS + interval))
    fi
    sleep 1
done
