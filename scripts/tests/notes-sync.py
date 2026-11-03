#!/usr/bin/env python3
# どこ: dotfiles/scripts/tests。使い捨て Git リポジトリのみを操作する。
# 何: 期待を各テストに先に記し、同期・除外・障害回復を検証する。
# なぜ: notes/GitHub/launchctl/setup/ネットに触れず回帰を検出する。
import hashlib
import os
from pathlib import Path
import signal
import subprocess
import tempfile
import time
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'notes-sync.sh'
ROOT = Path(tempfile.mkdtemp(prefix='notes-sync-test-', dir='/private/tmp'))
ENV = dict(os.environ, HOME=str(ROOT), XDG_CONFIG_HOME=str(ROOT / 'config'), GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL='/dev/null',
           GIT_TERMINAL_PROMPT='0', GIT_ALLOW_PROTOCOL='file')


def run(*args, env=None):
    return subprocess.check_output(args, env=env or ENV, stderr=subprocess.STDOUT,
                                   text=True, timeout=10).strip()


def git(repo, *args):
    return run('git', '-C', str(repo), *args)


def wait_for(predicate, timeout=15):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        if predicate():
            return
        time.sleep(0.15)
    raise AssertionError('期待を満たさず時間切れ')


class SyncTests(unittest.TestCase):
    def setUp(self):
        signal.alarm(45)  # 各件と全体の双方に上限を置く。
        self.base = ROOT / self._testMethodName
        self.base.mkdir()
        self.remote, self.work, self.other = [self.base / p for p in ('remote.git', 'work', 'other')]
        run('git', 'init', '--bare', '--initial-branch=main', str(self.remote))
        run('git', 'clone', str(self.remote), str(self.work))
        for key, value in [('user.email', 'test@example.invalid'), ('user.name', 'Local Test')]:
            git(self.work, 'config', key, value)
        (self.work / 'note.md').write_text('base\n')
        self.commit('seed')
        git(self.work, 'push', 'origin', 'main')
        run('git', 'clone', str(self.remote), str(self.other))
        for key, value in [('user.email', 'test@example.invalid'), ('user.name', 'Other Test')]:
            git(self.other, 'config', key, value)
        self.logpath = self.base / 'sync.log'
        self.notifications = self.base / 'notifications'
        self.stopfile = self.work / '.git/notes-sync.stopped'
        self.procs = []
        self.env = dict(ENV, TMPDIR=str(self.base), NOTES_SYNC_LOG=str(self.logpath),
                        NOTES_SYNC_DEBOUNCE='1', NOTES_SYNC_PULL_INTERVAL='2',
                        NOTES_SYNC_MAX_WAIT='5', NOTES_SYNC_NETWORK_TIMEOUT='2',
                        NOTES_SYNC_RETRY_DELAY='1', NOTES_SYNC_LOCK_AGE='2')
        notifier = self.base / 'notify'
        notifier.write_text('#!/bin/bash\nprintf "%s\\n" "$1" >> "' + str(self.notifications) + '"\n')
        notifier.chmod(0o755)
        self.env['NOTES_SYNC_NOTIFY'] = str(notifier)
        # sandbox は実 ps を拒否する。実プロセスの死活は kill -0 で確認し、
        # コマンド行だけを合成して所有者一致・pid 再利用の両分岐を確かめる。
        ps = self.base / 'ps'
        ps.write_text('#!/bin/sh\nif [ "$2" = "' + str(os.getpid()) + '" ]; then echo python; else echo "/bin/bash notes-sync.sh"; fi\n')
        ps.chmod(0o755)
        self.env['NOTES_SYNC_PS'] = str(ps)
        key = hashlib.sha256(str(self.work / '.git').encode()).hexdigest()
        self.lock = self.base / ('notes-sync-' + key + '.lock')
        print('\n期待: ' + self.shortDescription(), flush=True)

    def tearDown(self):
        for proc in self.procs:
            if proc.poll() is None:
                proc.terminate()
            proc.wait(timeout=8)
        signal.alarm(0)

    def commit(self, message):
        git(self.work, 'add', '-A')
        git(self.work, 'commit', '-m', message)

    def start(self, **settings):
        self.env.update(settings)
        proc = subprocess.Popen(['/bin/bash', str(SCRIPT), str(self.work)], env=self.env)
        self.procs.append(proc)
        wait_for(lambda: self.logpath.exists() and '起動:' in self.logs())
        return proc

    def logs(self):
        return self.logpath.read_text() if self.logpath.exists() else ''

    def notices(self):
        return self.notifications.read_text().splitlines() if self.notifications.exists() else []

    def count(self, repo=None):
        return int(git(repo or self.remote, 'rev-list', '--count', 'main'))

    def edit(self, text='changed\n'):
        (self.work / 'note.md').write_text(text)

    def instrument_git(self, body):
        # 本体の PATH 固定は保ち、テスト用コピーだけ Git の手前に障害を挿入する。
        bindir = self.base / 'bin'; bindir.mkdir()
        wrapper = bindir / 'git'
        wrapper.write_text('#!/bin/bash\n' + body + '\nexec /usr/bin/git "$@"\n')
        wrapper.chmod(0o755)
        script = self.base / 'notes-sync.sh'
        script.write_text(SCRIPT.read_text().replace('export PATH="', 'export PATH="' + str(bindir) + ':', 1))
        return script

    def test_disappearing_path_retry(self):
        """列挙済み4913を実際のadd直前に消し、再列挙した2回目で同期成功"""
        (self.work / '4913').write_text('temporary')
        self.edit()
        script = self.instrument_git('if [[ "$1" == add && -f 4913 ]]; then rm 4913; fi')
        proc = subprocess.Popen(['/bin/bash', str(script), str(self.work)], env=self.env)
        self.procs.append(proc)
        wait_for(lambda: self.count() == 2)
        self.assertIn('git add 失敗: 1/3', self.logs())
        self.assertNotIn('git add 失敗: 2/3', self.logs())
        self.assertFalse(self.stopfile.exists())
        self.assertNotIn('4913', git(self.remote, 'ls-tree', '-r', '--name-only', 'main'))

    def test_thousands_dirty_pull(self):
        """4000件の追跡済み未保存変更でもpipefailで脱落せずpullをスキップ"""
        paths = [self.work / ('note-' + str(n) + '-' + 'a'*80) for n in range(4000)]
        for path in paths: path.write_text('base')
        self.commit('many')
        for path in paths: path.write_text('changed')
        # 関数定義までを同じset -euo pipefailで実行。return 1まで到達したログを検査。
        harness = self.base / 'dirty.sh'
        harness.write_text(SCRIPT.read_text().split('branch_warned=0 push_failures=0')[0]
                           + 'branch_warned=0\npull_changes\n')
        result = subprocess.run(['/bin/bash', str(harness), str(self.work)], env=self.env, timeout=20)
        self.assertEqual(result.returncode, 1)
        self.assertIn('pull スキップ: 同期対象に未保存の変更あり', self.logs())
        self.assertFalse(self.stopfile.exists())

    def test_running_rotation(self):
        """常駐中も1MB超のログを退避し、開き直したログへ書き込む"""
        proc = self.start(NOTES_SYNC_MAINTENANCE_INTERVAL='2')
        with self.logpath.open('a') as f: f.write('x' * 1048577)
        backup = Path(str(self.logpath) + '.1')
        wait_for(backup.exists)
        self.assertGreater(backup.stat().st_size, 1048576)
        git(self.work, 'checkout', '-b', 'topic')
        wait_for(lambda: 'main 以外' in self.logs())
        self.assertIsNone(proc.poll())
        self.assertNotIn('main 以外', backup.read_text())

    def test_ignored_scan_interval(self):
        """毎秒snapshotしてもignored全列挙は指定間隔まで繰り返さない"""
        trace = self.base / 'trace'
        self.start(GIT_TRACE=str(trace), NOTES_SYNC_MAINTENANCE_INTERVAL='6')
        wait_for(lambda: trace.exists() and '--ignored' in trace.read_text())
        time.sleep(3)
        self.assertEqual(trace.read_text().count('--ignored'), 1)
        wait_for(lambda: trace.read_text().count('--ignored') == 2)

    def test_autostash_conflict(self):
        """除外済み追跡ファイルのautostash復元衝突で停止・通知しstash内容を保持"""
        (self.work / '.DS_Store').write_text('base noise\n'); self.commit('noise')
        git(self.work, 'push'); git(self.other, 'pull')
        (self.work / '.DS_Store').write_text('local noise\n')
        (self.other / '.DS_Store').write_text('remote noise\n')
        git(self.other, 'add', '-A'); git(self.other, 'commit', '-m', 'remote noise'); git(self.other, 'push')
        proc = self.start(); wait_for(self.stopfile.exists)
        self.assertIn('stash に残っています', self.logs())
        self.assertIn('local noise', git(self.work, 'show', 'stash@{0}:.DS_Store'))
        self.assertIn('<<<<<<<', (self.work / '.DS_Store').read_text())
        self.assertTrue(git(self.work, 'ls-files', '-u'))
        time.sleep(3)
        self.assertEqual(len(self.notices()), 1)
        self.assertEqual(self.count(), 3)
        self.assertIsNone(proc.poll())

    def test_debounce_delete_noise(self):
        """連続保存は最後から3秒待って1 commit、削除も反映し一時ファイルは除外"""
        self.start(NOTES_SYNC_DEBOUNCE='3')
        folder = self.work / 'deep folder'; folder.mkdir()
        target = folder / 'a\nb.md'; target.write_text('one')
        time.sleep(1.2); self.edit()
        time.sleep(1.5); self.assertEqual(self.count(), 1)
        wait_for(lambda: self.count() == 2)
        for name in ('.DS_Store', 'memo.swp', 'memo~', 'memo.tmp'):
            (folder / name).write_text('noise')
        target.unlink()
        wait_for(lambda: self.count() == 3)
        self.assertEqual(git(self.remote, 'ls-tree', '-r', '--name-only', 'main'), 'note.md')

    def test_tracked_excluded_pull(self):
        """追跡済み .DS_Store の汚れを保持しつつ、他 clone の変更を pull"""
        (self.work / '.DS_Store').write_text('old'); self.commit('noise')
        git(self.work, 'push'); git(self.other, 'pull')
        (self.work / '.DS_Store').write_text('local noise')
        (self.other / 'remote.md').write_text('remote')
        git(self.other, 'add', '-A'); git(self.other, 'commit', '-m', 'remote'); git(self.other, 'push')
        self.start()
        wait_for(lambda: (self.work / 'remote.md').exists())
        self.assertEqual((self.work / '.DS_Store').read_text(), 'local noise')
        self.assertFalse(self.stopfile.exists())

    def test_dirty_pull_reason(self):
        """同期中にも対象が汚れていたら pull を飛ばした理由を記録"""
        hook = self.work / '.git/hooks/post-commit'
        hook.write_text('#!/bin/sh\necho hook-edit >> note.md\n'); hook.chmod(0o755)
        self.edit(); self.start()
        wait_for(lambda: 'pull スキップ: 同期対象' in self.logs())

    def test_old_pidless_lock(self):
        """古い pid 不在ロックと残った作業ファイルを回収"""
        self.lock.mkdir(); (self.lock / 'paths').touch()
        reclaim = self.lock / 'reclaim'; reclaim.mkdir()
        os.utime(reclaim, (time.time()-10, time.time()-10))
        os.utime(self.lock, (time.time()-10, time.time()-10))
        self.start(); self.edit(); wait_for(lambda: self.count() == 2)

    def test_fresh_pidless_lock(self):
        """作成直後で pid 不在のロックは奪わず異常終了し再起動を促す"""
        self.lock.mkdir()
        self.env['NOTES_SYNC_LOCK_AGE'] = '60'
        result = subprocess.run(['/bin/bash', str(SCRIPT), str(self.work)], env=self.env, timeout=5)
        self.assertEqual(result.returncode, 1); self.assertFalse(self.logpath.exists())

    def test_reused_pid(self):
        """生きている無関係なプロセスの pid を再利用したロックを回収"""
        self.lock.mkdir(); (self.lock / 'pid').write_text(str(os.getpid()))
        self.start(); self.edit(); wait_for(lambda: self.count() == 2)

    def test_duplicate(self):
        """稼働中の notes-sync のロックは奪わず二重起動を終了"""
        first = self.start()
        second = subprocess.run(['/bin/bash', str(SCRIPT), str(self.work)], env=self.env, timeout=5)
        self.assertEqual(second.returncode, 0)
        self.assertEqual((self.lock / 'pid').read_text().strip(), str(first.pid))

    def test_network_timeout(self):
        """止まった Git 通信を2秒で打ち切り、子も終了し復旧後再試行"""
        upload = self.base / 'upload'
        upload.write_text('#!/bin/sh\necho $$ > "' + str(self.base / 'child') + '"\nexec sleep 30\n'); upload.chmod(0o755)
        git(self.work, 'config', 'remote.origin.uploadpack', str(upload))
        proc = self.start(); self.edit()
        wait_for(lambda: 'pull 失敗・時間切れ' in self.logs())
        self.assertIsNone(proc.poll())
        child = (self.base / 'child').read_text().strip()
        self.assertNotEqual(subprocess.run(['kill', '-0', child], stderr=subprocess.DEVNULL).returncode, 0)
        git(self.work, 'config', '--unset', 'remote.origin.uploadpack')
        wait_for(lambda: self.count() == 2)

    def test_large_and_secret(self):
        """50MB超・秘密候補は追跡済みでも add 除外し、候補ごとに通知は1回"""
        names = ['.env', '.env.prod', 'a.pem', 'a.key', 'id_rsa.pub', 'id_ed25519', 'mycredentials.txt', 'a.p12']
        for name in names: (self.work / name).write_text('secret')
        self.commit('tracked secrets'); git(self.work, 'push')
        for name in names: (self.work / name).write_text('changed secret')
        with (self.work / 'large.bin').open('wb') as f: f.truncate(50*1024*1024+1)
        self.start(); self.edit(); wait_for(lambda: self.count() == 3)
        time.sleep(4)
        self.assertEqual(len(self.notices()), 4)
        self.assertIn("ほか 6 件", self.notices()[-1])
        self.assertEqual(self.logs().count('add 除外:'), 9)
        self.assertNotIn('large.bin', git(self.remote, 'ls-tree', '-r', '--name-only', 'main'))
        self.assertEqual(git(self.remote, 'show', 'main:.env'), 'secret')

    def test_ignored_secret(self):
        """Git が無視する .env も1回通知し、同期対象には加えない"""
        (self.work / '.gitignore').write_text('.env\n')
        (self.work / '.env').write_text('secret')
        self.start(); wait_for(lambda: len(self.notices()) == 1)
        wait_for(lambda: self.count() == 2); time.sleep(2)
        self.assertEqual(len(self.notices()), 1)
        self.assertNotIn('.env', git(self.remote, 'ls-tree', '-r', '--name-only', 'main'))

    def test_unknown_owner(self):
        """ps が拒否され所有者を確認できない場合はロックを奪わず理由を記録"""
        self.lock.mkdir(); (self.lock / 'pid').write_text(str(os.getpid()))
        self.env['NOTES_SYNC_PS'] = '/usr/bin/false'
        result = subprocess.run(['/bin/bash', str(SCRIPT), str(self.work)], env=self.env, timeout=5)
        self.assertEqual(result.returncode, 1)
        self.assertIn('所有者を確認できない', self.logs())
        self.assertEqual((self.lock / 'pid').read_text(), str(os.getpid()))

    def test_push_failure_notice_reset(self):
        """push 連続3回失敗で1通知、成功後の再失敗では改めて1通知"""
        hook = self.remote / 'hooks/pre-receive'
        hook.write_text('#!/bin/sh\nexit 1\n'); hook.chmod(0o755)
        self.edit(); proc = self.start()
        wait_for(lambda: len(self.notices()) == 1)
        wait_for(lambda: '連続 4 回' in self.logs())
        self.assertEqual(len(self.notices()), 1); self.assertIsNone(proc.poll())
        hook.unlink(); wait_for(lambda: self.count() == 2)
        time.sleep(1)
        hook.write_text('#!/bin/sh\nexit 1\n'); hook.chmod(0o755)
        self.edit('again and longer\n')
        wait_for(lambda: len(self.notices()) == 2)

    def test_add_lock_retry(self):
        """index.lock による add 失敗は再試行し、解除後成功"""
        lock = self.work / '.git/index.lock'; lock.touch()
        self.edit(); self.start()
        wait_for(lambda: '失敗: 1/3' in self.logs()); lock.unlink()
        wait_for(lambda: self.count() == 2)
        self.assertFalse(self.stopfile.exists())

    def test_commit_retry(self):
        """commit が2回失敗しても3回目で成功し停止しない"""
        hook = self.work / '.git/hooks/pre-commit'
        hook.write_text('#!/bin/sh\nn=$(cat .git/attempt 2>/dev/null || echo 0)\nn=$((n+1))\necho "$n" > .git/attempt\n[ "$n" -ge 3 ]\n'); hook.chmod(0o755)
        self.edit(); self.start(); wait_for(lambda: self.count() == 2)
        self.assertEqual((self.work / '.git/attempt').read_text().strip(), '3')
        self.assertFalse(self.stopfile.exists())

    def test_stop_resume(self):
        """add の3回失敗で停止・手順通知1回、停止ファイル削除で同じプロセスが再開"""
        lock = self.work / '.git/index.lock'; lock.touch()
        self.edit(); proc = self.start()
        wait_for(lambda: self.stopfile.exists() and len(self.notices()) == 1)
        self.assertEqual(len(self.notices()), 1)
        self.assertIn('削除すると自動再開', self.notices()[0])
        self.assertIsNone(proc.poll()); lock.unlink(); self.stopfile.unlink()
        wait_for(lambda: self.count() == 2)

    def test_empty_pathspec(self):
        """対象が空なら git add を呼ばず除外ファイルも stage しない"""
        (self.work / 'note.md').unlink(); self.commit('empty'); git(self.work, 'push')
        (self.work / '.env').write_text('secret')
        trace = self.base / 'trace'; self.start(GIT_TRACE=str(trace))
        time.sleep(4)
        self.assertNotIn(' add ', trace.read_text())
        self.assertEqual(git(self.work, 'diff', '--cached', '--name-only'), '')

    def test_branch_resume(self):
        """main 以外では1回通知して待ち、main に戻れば自動保存を再開"""
        git(self.work, 'checkout', '-b', 'topic')
        proc = self.start(); wait_for(lambda: len(self.notices()) == 1)
        time.sleep(2); self.assertEqual(len(self.notices()), 1)
        self.assertIsNone(proc.poll()); self.assertFalse(self.stopfile.exists())
        git(self.work, 'checkout', 'main'); self.edit()
        wait_for(lambda: self.count() == 2)
        self.assertIn('main に復帰', self.logs())

    def test_max_wait(self):
        """毎秒編集し続けても最大待ち5秒で commit/push"""
        self.start(NOTES_SYNC_DEBOUNCE='10')
        for n in range(9):
            self.edit('x' * (n+1)); time.sleep(1)
        self.assertGreaterEqual(self.count(), 2)

    def test_metadata_only(self):
        """同じサイズ・mtime の内容変更は検出せず、メタデータ変更で検出"""
        self.start(NOTES_SYNC_PULL_INTERVAL='60'); time.sleep(3)
        path = self.work / 'note.md'; old = path.stat()
        path.write_text('same\n'); os.utime(path, ns=(old.st_atime_ns, old.st_mtime_ns))
        time.sleep(3); self.assertEqual(self.count(), 1)
        path.write_text('longer content\n'); wait_for(lambda: self.count() == 2)

    def test_rotation_quiet(self):
        """起動時1MB超のログを .1 に退避し、無変更の定期成功ログを増やさない"""
        self.logpath.write_text('x' * 1048577); self.start()
        self.assertEqual(Path(str(self.logpath)+'.1').stat().st_size, 1048577)
        time.sleep(5)
        self.assertNotIn('完了', self.logs()); self.assertNotIn('up to date', self.logs())

    def test_conflict_stop(self):
        """rebase 競合では変更を保持して停止、待機中の通知は1回"""
        self.edit('local\n'); (self.other / 'note.md').write_text('remote\n')
        git(self.other, 'add', '-A'); git(self.other, 'commit', '-m', 'other'); git(self.other, 'push')
        proc = self.start(); wait_for(self.stopfile.exists)
        time.sleep(2)
        self.assertTrue(git(self.work, 'ls-files', '-u'))
        self.assertEqual(len(self.notices()), 1); self.assertIsNone(proc.poll())


if __name__ == '__main__':
    print('検証資料: ' + str(ROOT), flush=True)
    if os.getpgrp() != os.getpid():
        os.setsid()
    watchdog = os.fork()
    if watchdog == 0:
        time.sleep(300)
        os.killpg(os.getpgid(os.getppid()), signal.SIGKILL)
        os._exit(0)
    def case_timeout(signum, frame):
        raise TimeoutError('1件45秒の上限')
    signal.signal(signal.SIGALRM, case_timeout)
    try:
        unittest.main(verbosity=2)
    finally:
        os.kill(watchdog, signal.SIGTERM)
        os.waitpid(watchdog, 0)
