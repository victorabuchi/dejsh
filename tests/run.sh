#!/usr/bin/env bash
# dejsh test suite. Self-contained: builds its own fixtures in a temp dir. Usage: bash tests/run.sh
cd "$(dirname "$0")/.." || exit 1
D=$PWD/dejsh
W=$(mktemp -d 2>/dev/null || mktemp -d -t dejsh); trap 'rm -rf "$W"' EXIT
pass=0; fail=0
# Fake credentials are assembled at runtime so no secret scanner mistakes this file for a leak.
GHTOK="gh""p_abcdefghijklmnopqrstuvwxyz0123456789"
AWSK="wJalrXUtnFEMI/K7MDENG/bPx""RfiCYEXAMPLEKEY"
STRIPE="sk_""live_abcdefghijklmnopqrstuvwx1234"
GOOG="AI""zaSyA-1234567890abcdefghijklmnopqrstuv"
JWT="ey""JhbGciOiJIUzI1NiJ9.ey""JzdWIiOiIxMjM0NTY3ODkwIn0.abcdefghijklmnop"
t() { local name=$1; shift; if "$@"; then pass=$((pass+1)); printf '  ok    %s\n' "$name"; else fail=$((fail+1)); printf '  FAIL  %s\n' "$name"; fi; }
has()   { printf '%s' "$1" | grep -qF -- "$2"; }
hasnt() { ! printf '%s' "$1" | grep -qF -- "$2"; }
strip() { sed 's/\x1b\[[0-9;]*m//g'; }
jsonok() { python3 -c 'import sys,json; json.load(sys.stdin)' 2>/dev/null; }
# Drive an interactive shell through a real pseudo-terminal (some shells only fire prompt hooks on a tty).
# usage: pty_session HOME XDG_CONFIG_HOME shell [args...]; feeds a fixed list of commands, then exit.
pty_session() { python3 - "$@" <<'PY'
import os, pty, sys, time, select, signal
home, cfg, argv = sys.argv[1], sys.argv[2], sys.argv[3:]
env = dict(os.environ, HOME=home, XDG_CONFIG_HOME=cfg, TERM="xterm", ZDOTDIR=home)
pid, fd = pty.fork()
if pid == 0:
    os.execvpe(argv[0], argv, env)
log = open(os.environ["PTY_LOG"], "ab") if os.environ.get("PTY_LOG") else None
buf = b""
def pump(t, quiet=None):
    """Read for up to t seconds; answer terminal capability queries; return early after `quiet` seconds of silence."""
    global buf
    end = time.time() + t; last = time.time()
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.1)
        if r:
            try: d = os.read(fd, 4096)
            except OSError: return
            if not d: return
            last = time.time(); buf += d
            if log: log.write(d); log.flush()
            if b"\x1b[c" in buf or b"\x1b[0c" in buf: os.write(fd, b"\x1b[?62;22c"); buf = buf.replace(b"\x1b[c", b"").replace(b"\x1b[0c", b"")
            if b"\x1b[?u" in buf: os.write(fd, b"\x1b[?0u"); buf = buf.replace(b"\x1b[?u", b"")
            if b"\x1b[>q" in buf: os.write(fd, b"\x1bP>|xterm(1)\x1b\\\\"); buf = buf.replace(b"\x1b[>q", b"")
            buf = buf[-64:]
        elif quiet and time.time() - last >= quiet:
            return
pump(8, quiet=1.5)
cmds = [":", "echo hello", "false", "export API_TOKEN=abc123"]
if os.environ.get("PTY_SECRET"): cmds.append("export SOME_PAT=" + os.environ["PTY_SECRET"])
cmds += ["echo after", "exit"]
for cmd in cmds:
    os.write(fd, (cmd + "\r").encode()); pump(2.0, quiet=0.8)
end = time.time() + 5
while time.time() < end:
    try:
        p, _ = os.waitpid(pid, os.WNOHANG)
        if p: break
    except ChildProcessError: break
    time.sleep(0.1)
else:
    try: os.kill(pid, signal.SIGKILL)
    except ProcessLookupError: pass
PY
}
# Run a command on a real pty and answer any "[y/N]" prompt with y. Prints the terminal output.
pty_run() { python3 - "$@" <<'PY'
import os, pty, sys, time, select
argv = sys.argv[1:]
pid, fd = pty.fork()
if pid == 0: os.execvpe(argv[0], argv, os.environ)
out = b""; sent = False; end = time.time() + 20
while time.time() < end:
    r, _, _ = select.select([fd], [], [], 0.2)
    if r:
        try: d = os.read(fd, 4096)
        except OSError: break
        if not d: break
        out += d
        if b"[y/N]" in out and not sent: time.sleep(0.3); os.write(fd, b"y\r"); sent = True
sys.stdout.write(out.decode(errors="replace"))
try: os.waitpid(pid, 0)
except ChildProcessError: pass
PY
}

section() { printf '\n%s\n' "$1"; }

# ---------- fixtures ----------
H=$W/hist
awk -v aws="$AWSK" -v gh="$GHTOK" 'BEGIN{ t=1760000000
 for(d=0;d<40;d++){ t+=86400
  for(k=0;k<3;k++){ print ": " t ":0;git add -A"; t+=20; print ": " t ":0;git commit -m \"wip\""; t+=30; print ": " t ":0;git push origin main"; t+=300 }
  print ": " t ":0;cd ~/projects/my-awesome-app"; t+=5
  print ": " t ":0;docker compose up -d --build"; t+=5
  print ": " t ":0;ls -la"; t+=5
  if(d%5==0){ print ": " t ":0;gti status"; t+=3 }
  if(d%3==0){ print ": " t ":0;kubectl get pods -n production"; t+=3 }
  print ": " t ":0;git status"; t+=3; print ": " t ":0;git log"; t+=3 }
 print ": " t ":0;export AWS_SECRET_ACCESS_KEY=" aws
 print ": " t ":0;git clone https://" gh "@github.com/x/y.git"
 print ": " t ":0;mysql -u root -phunter2secret mydb"
 print ": " t ":0;export EDITOR=vim" }' > "$H"

J=$W/journal.tsv; NOW=$(date +%s); P1=$W/projA; P2=$W/projB; mkdir -p "$P1" "$P2"
awk -v now="$NOW" -v p1="$P1" -v p2="$P2" 'function row(rc,d,cwd,c){ printf "%d\t%d\t%d\t%s\t%s\n", t, rc, d, cwd, c; t+=d+7 }
 BEGIN{ t=now-20*86400
  for(i=0;i<5;i++){ t+=3600*6
   row(1,2,p2,"npm start"); row(0,41,p2,"npm install"); row(0,3,p2,"npm start")
   row(127,0,p2,"jq .name package.json"); row(0,18,p2,"brew install jq"); row(0,0,p2,"jq .name package.json")
   row(0,95,p2,"docker compose build"); row(1,9,p2,"pytest -x"); row(0,9,p2,"pytest -x") }
  t=now-3*3600
  row(0,1,p1,"git status"); row(0,3,p1,"shellcheck x"); row(0,2,p1,"vim README.md"); row(0,1,p1,"git add -A"); row(0,1,p1,"git commit -m docs"); row(1,1,p1,"git push origin main") }' > "$J"
export DEJSH_JOURNAL=$J

section "basics"
t "version prints" has "$("$D" --version)" "dejsh "
out=$("$D" help | strip); t "help lists fix"   has "$out" "dejsh fix"
out=$("$D" -f "$H" | strip); t "checkup header" has "$out" "DEJSH CHECKUP"; t "checkup counts commands" has "$out" "commands in"

section "alias"
out=$("$D" alias -f "$H" | strip)
t "suggests git push alias" has "$out" "alias gpom='git push origin main'"
t "suggests compose alias"  has "$out" "docker compose up -d --build"
t "reports savings"         has "$out" "keystrokes"
out=$("$D" alias --raw -f "$H")
t "raw is alias lines only" test -z "$(printf '%s\n' "$out" | grep -v '^alias ')"
t "never aliases secrets"   hasnt "$out" "wJalr"

section "typos"
out=$("$D" typos -f "$H" | strip); t "finds gti -> git" has "$out" "gti"; t "gives fix alias" has "$out" "alias gti='git'"

section "flows"
out=$("$D" flows -f "$H" | strip)
t "finds add->commit->push" has "$out" "git add → git commit → git push"
t "does not repeat rotations" test "$(printf '%s' "$out" | grep -c 'git push → git add')" -eq 0

section "leaks"
out=$("$D" leaks -f "$H" | strip)
t "finds AWS assignment"  has "$out" "Secret assignment"
t "finds GitHub token"    has "$out" "GitHub token"
t "finds DB password"     has "$out" "Database password"
t "never prints full secret" hasnt "$out" "$AWSK"
t "never prints full token"  hasnt "$out" "$GHTOK"
t "never prints db password" hasnt "$out" "hunter2secret"
P=$W/pat; printf ': 1:0;echo %s\n: 2:0;echo %s\n: 3:0;export X=%s\n: 4:0;echo hello\n' "$GOOG" "$JWT" "$STRIPE" > "$P"
out=$("$D" leaks -f "$P" | strip)
t "Google key pattern" has "$out" "Google API key"; t "JWT pattern" has "$out" "JWT"; t "Stripe pattern" has "$out" "Stripe live key"
t "clean history is clean" has "$("$D" leaks -f "$W/pat2" 2>/dev/null; printf ': 1:0;ls\n' > "$W/pat2"; "$D" leaks -f "$W/pat2" | strip)" "nothing that looks like a credential"
cp "$H" "$W/scrubtest"; t "scrub refuses without a tty" sh -c "\"$D\" leaks --scrub -f \"$W/scrubtest\" </dev/null >/dev/null 2>&1; [ \$? -ne 0 ]"
t "scrub left file untouched" test "$(wc -l < "$W/scrubtest")" -eq "$(wc -l < "$H")"

section "find"
out=$("$D" find -f "$H" kube prod | strip); t "find matches keywords" has "$out" "kubectl get pods -n production"
t "find --raw prints command" test "$("$D" find -f "$H" --raw docker compose)" = "docker compose up -d --build"

section "fish history"
F=$W/fish_history; printf -- '- cmd: git status\n  when: 1760000000\n- cmd: export K=%s\n  when: 1760000200\n- cmd: git status\n  when: 1760000300\n  paths:\n    - foo\n' "$STRIPE" > "$F"
t "fish history parsed" has "$("$D" find -f "$F" git | strip)" "2×  git status"
t "fish leak found" has "$("$D" leaks -f "$F" | strip)" "Stripe live key"

section "json"
for c in alias typos flows leaks export; do t "json valid: $c" sh -c "\"$D\" $c -f \"$H\" --json | python3 -c 'import sys,json; json.load(sys.stdin)'"; done
t "json valid: checkup" sh -c "\"$D\" -f \"$H\" --json | python3 -c 'import sys,json; json.load(sys.stdin)'"
t "json valid: fixes"   sh -c "\"$D\" fixes --json | python3 -c 'import sys,json; json.load(sys.stdin)'"
t "json valid: find"    sh -c "\"$D\" find -f \"$H\" kube --json | python3 -c 'import sys,json; json.load(sys.stdin)'"

section "memory: fixes / fix"
out=$("$D" fixes | strip)
t "learns npm install fixes npm start" has "$out" "npm install"
t "learns brew install jq for missing jq" has "$out" "brew install jq"
t "spots flaky command" has "$out" "flaky"
out=$("$D" fix | strip)
t "fix shows last failure" has "$out" "git push origin main"
t "fix explains exit code" has "$out" "exit code 1"

section "fix learning ignores noisy retries"
J3=$W/j3.tsv; awk -v now="$NOW" -v d="$W" 'function r(rc,c){ printf "%d\t%d\t1\t%s\t%s\n", t, rc, d, c; t+=10 }
 BEGIN{ t=now-9000; for(i=0;i<3;i++){ r(128,"git status # fails"); r(129,"git init # the fix"); r(128,"git status # works"); r(0,"rm -rf .git"); r(128,"git status"); r(0,"git init"); r(0,"git status") } }' > "$J3"
out=$(DEJSH_JOURNAL=$J3 "$D" fixes | strip)
t "fix is the step right before success" has "$out" "→ git init  (worked"
t "fix excludes earlier noise" hasnt "$out" "rm -rf .git ; git init"

section "memory: resume / slow / script"
out=$(cd "$P1" && "$D" resume | strip); t "resume shows session" has "$out" "WHERE YOU LEFT OFF"; t "resume flags failing stop" has "$out" "stopped on a failing command"
out=$("$D" resume --all | strip); t "resume --all lists projects" has "$out" "projA"
out=$("$D" slow | strip); t "slow ranks docker compose" has "$out" "docker compose"
out=$("$D" script -n 3 --since 4h); t "script has shebang" has "$out" "#!/usr/bin/env bash"; t "script uses strict mode" has "$out" "set -euo pipefail"; t "script skips failed command" hasnt "$out" "git push origin main"
t "script is valid bash" sh -c "\"$D\" script -n 3 --since 4h | bash -n"

section "audits: danger / coach / wrapped / export / compare"
D2=$W/dh; printf ': 1:0;rm -rf ~\n: 2:0;git push -f origin main\n: 3:0;curl -s https://x.sh | sudo bash\n: 4:0;git push --force-with-lease\n' > "$D2"
out=$("$D" danger -f "$D2" | strip); t "danger: rm -rf" has "$out" "rm -rf"; t "danger: force push" has "$out" "git push --force"; t "danger: curl|sh" has "$out" "curl | sh"
t "danger: ignores force-with-lease" test "$(printf '%s' "$out" | grep -c 'force-with-lease$')" -eq 0
out=$("$D" coach -f "$H" | strip); t "coach runs" has "$out" "HABIT COACH"
out=$("$D" wrapped -f "$H" | strip); t "wrapped card" has "$out" "TERMINAL WRAPPED"; t "wrapped personality" has "$out" "The Git Gardener"
"$D" export -f "$H" > "$W/me.tsv"; printf 'terraform plan\t40\nkubectl get\t30\nfzf\t22\n' > "$W/them.tsv"
out=$("$D" compare "$W/them.tsv" -f "$H" | strip); t "compare: they use, you never" has "$out" "terraform plan"; t "compare: shared count" has "$out" "shared tools"
t "export has no arguments/paths" test -z "$(grep -E '/|~' "$W/me.tsv")"

section "recorder"
t "zsh hook generated"  has "$("$D" hook zsh)"  "precmd"
t "bash hook generated" has "$("$D" hook bash)" "PROMPT_COMMAND"
t "fish hook generated" has "$("$D" hook fish)" "fish_postexec"
FH=$W/home; mkdir -p "$FH"; HOME=$FH SHELL=/bin/bash "$D" hook --install >/dev/null 2>&1; HOME=$FH SHELL=/bin/bash "$D" hook --install >/dev/null 2>&1
t "install is idempotent" test "$(grep -c 'dejsh recorder (bash)' "$FH/.bashrc")" -eq 1
if command -v zsh >/dev/null 2>&1; then
  Z=$W/zhome; mkdir -p "$Z"; "$D" hook zsh > "$Z/.zshrc"
  printf 'echo hello\nfalse\nexport API_TOKEN=abc123\n echo hidden\ndejsh fix\nexit\n' | HOME=$Z ZDOTDIR=$Z zsh -i >/dev/null 2>&1
  jr=$(cat "$Z/.dejsh/journal.tsv" 2>/dev/null)
  t "zsh recorder records commands" has "$jr" "echo hello"
  t "zsh recorder captures exit code" has "$jr" "$(printf '\t1\t')"
  t "zsh recorder skips secrets" hasnt "$jr" "API_TOKEN"
  t "zsh recorder skips leading-space" hasnt "$jr" "hidden"
  t "zsh recorder skips dejsh itself" hasnt "$jr" "dejsh fix"
fi
Bh=$W/bhome; mkdir -p "$Bh"; "$D" hook bash > "$Bh/.bashrc"
printf 'echo hello\nfalse\nexport API_TOKEN=abc123\nexit\n' | HOME=$Bh bash --rcfile "$Bh/.bashrc" -i >/dev/null 2>&1
jr=$(cat "$Bh/.dejsh/journal.tsv" 2>/dev/null)
t "bash recorder records commands" has "$jr" "echo hello"
t "bash recorder captures exit code" has "$jr" "$(printf '\t1\t')"
t "bash recorder skips secrets" hasnt "$jr" "API_TOKEN"

section "smarter output (v0.7)"
H2=$W/hist2
awk 'BEGIN{ t=1760000000; for(i=1;i<=8;i++){ t+=3600; print ": " t ":0;git add -A"; t+=15; print ": " t ":0;git commit -m \"change " i " in module\""; t+=20; print ": " t ":0;git push origin main" } }' > "$H2"
out=$("$D" alias -f "$H2" | strip)
t "stem alias for varying args"  has "$out" "='git commit -m'"
t "stem alias says to add arg"   has "$out" "add your argument"
out=$("$D" alias -f "$H2" --json); t "alias json flags takes_argument" has "$out" '"takes_argument":1'
out=$("$D" flows -f "$H2" | strip)
t "flow found with varying messages" has "$out" "git add → git commit → git push"
t "flow macro does not freeze one message" hasnt "$out" "change 3 in module"
t "flow macro keeps stable steps" has "$out" "git add -A && git commit && git push origin main"
for c in danger coach; do t "json valid: $c" sh -c "\"$D\" $c -f \"$D2\" --json | python3 -c 'import sys,json; json.load(sys.stdin)'"; done
t "json valid: slow" sh -c "\"$D\" slow --json | python3 -c 'import sys,json; json.load(sys.stdin)'"
t "json valid: resume --all" sh -c "\"$D\" resume --all --json | python3 -c 'import sys,json; json.load(sys.stdin)'"
t "json valid: resume (session)" sh -c "cd \"$P1\" && \"$D\" resume --json | python3 -c 'import sys,json; json.load(sys.stdin)'"
out=$("$D" danger -f "$D2" --json); t "danger json has pattern field" has "$out" '"pattern":"rm -rf'
out=$("$D" slow --json); t "slow json has seconds" has "$out" '"total_seconds"'

if command -v fish >/dev/null 2>&1; then
  FF=$(mktemp -d); mkdir -p "$FF/.config/fish"; "$D" hook fish > "$FF/.config/fish/config.fish"
  PTY_LOG=$FF/pty.log pty_session "$FF" "$FF/.config" fish -i >/dev/null 2>&1
  jr=$(cat "$FF/.dejsh/journal.tsv" 2>/dev/null)
  case $jr in *"echo hello"*) ;; *) echo "  --- fish diagnostics: version=$(fish --version) journal=[$jr]"; tr -c '[:print:]\n' '?' < "$FF/pty.log" 2>/dev/null | tail -25;; esac
  t "fish recorder records commands"    has "$jr" "echo hello"
  t "fish recorder captures exit code"  has "$jr" "$(printf '\t1\t')"
  t "fish recorder skips secrets"       hasnt "$jr" "API_TOKEN"
fi
if command -v zsh >/dev/null 2>&1; then
  PZ=$(mktemp -d); "$D" hook zsh > "$PZ/.zshrc"
  pty_session "$PZ" "$PZ/.config" zsh -i >/dev/null 2>&1
  jr=$(cat "$PZ/.dejsh/journal.tsv" 2>/dev/null)
  t "zsh recorder works on a real tty too" has "$jr" "echo hello"
  t "zsh recorder tty: exit code"          has "$jr" "$(printf '\t1\t')"
  t "zsh recorder tty: skips secrets"      hasnt "$jr" "API_TOKEN"
fi

section "shell completions (v0.8)"
cb=$("$D" completion bash)
t "bash completion defines function" has "$cb" "_dejsh()"
comp() { COMP_WORDS=("$@"); COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 )); COMPREPLY=(); _dejsh; echo "${COMPREPLY[*]}"; }
eval "$cb"
t "bash: 'le' completes to leaks"          test "$(comp dejsh le)" = "leaks"
t "bash: fix offers --run"                 test "$(comp dejsh fix --)" = "--run"
t "bash: leaks offers --scrub"             test "$(comp dejsh leaks --s)" = "--scrub"
t "bash: resume offers --all"              has "$(comp dejsh resume --)" "--all"
t "bash: script --since offers windows"    has "$(comp dejsh script --since '')" "2h"
t "bash: hook offers shells"               has "$(comp dejsh hook '')" "fish"
t "bash: top level lists all commands"     has "$(comp dejsh '')" "completion"
t "bash: -f completes filenames"           test -n "$(cd "$W" && comp dejsh alias -f hi)"
t "zsh completion has #compdef"            has "$("$D" completion zsh)" "#compdef dejsh"
t "fish completion has subcommands"        has "$("$D" completion fish)" "__fish_use_subcommand"
t "completion rejects unknown shell"       sh -c "\"$D\" completion tcsh >/dev/null 2>&1; [ \$? -ne 0 ]"
for sh in zsh bash fish; do
  CH=$(mktemp -d); HOME=$CH "$D" completion $sh --install >/dev/null 2>&1; HOME=$CH "$D" completion $sh --install >/dev/null 2>&1
  t "completion install idempotent ($sh)" test "$(grep -rh 'dejsh completion >>>' "$CH" | wc -l | tr -d ' ')" -eq 1
done
if command -v zsh >/dev/null 2>&1; then
  printf 'autoload -Uz compinit\ncompinit -u -d "%s/zcd" 2>/dev/null\neval "$("%s" completion zsh)"\nprint -r -- "${_comps[dejsh]}"\n' "$W" "$D" > "$W/zt.zsh"
  t "zsh completion registers with compinit" test "$(zsh -f "$W/zt.zsh" 2>/dev/null | tail -1)" = "_dejsh"
  # the way Homebrew installs it: a file named _dejsh on fpath, autoloaded by compinit
  ZF=$(mktemp -d); "$D" completion zsh > "$ZF/_dejsh"
  printf 'fpath=("%s" $fpath)\nautoload -Uz compinit\ncompinit -u -d "%s/zcd2" 2>/dev/null\nprint -r -- "${_comps[dejsh]}"\n' "$ZF" "$W" > "$W/zt2.zsh"
  t "zsh completion registers via fpath (Homebrew style)" test "$(zsh -f "$W/zt2.zsh" 2>/dev/null | tail -1)" = "_dejsh"
  t "zsh file calls itself when autoloaded" has "$(cat "$ZF/_dejsh")" '_dejsh "$@"'
fi
if command -v fish >/dev/null 2>&1; then
  printf '%s\n' "$("$D" completion fish)" > "$W/c.fish"
  t "fish completion loads without error" fish -c "source $W/c.fish"
  t "fish completes 'le' to leaks" has "$(fish -c "source $W/c.fish; complete -C 'dejsh le'")" "leaks"
  t "fish completes fix --run" has "$(fish -c "source $W/c.fish; complete -C 'dejsh fix --'")" "run"
fi

section "multi-step fix --run and the guard (v0.9)"
FX=$(mktemp -d); mkdir -p "$FX/build"; touch "$FX/build/keep"
mkj() { awk -v now="$NOW" -v d="$FX" -v a="$1" -v b="$2" 'function r(rc,c){printf "%d\t%d\t1\t%s\t%s\n", t, rc, d, c; t+=10} BEGIN{ t=now-9000; for(i=0;i<3;i++){ r(1,"npm start"); r(0,a); if(b!="") r(0,b); r(0,"npm start") } r(1,"npm start") }' > "$3"; }
mkj "touch a.txt" "touch b.txt" "$W/j4.tsv"
out=$(DEJSH_JOURNAL=$W/j4.tsv pty_run "$D" fix --run | strip)
t "multi-step fix lists the steps"   has "$out" "Run these 2 commands"
t "multi-step fix ran step 1"        test -f "$FX/a.txt"
t "multi-step fix ran step 2"        test -f "$FX/b.txt"
mkj "rm -rf build" "" "$W/j5.tsv"
out=$(DEJSH_JOURNAL=$W/j5.tsv pty_run "$D" fix --run | strip)
t "risky fix is refused"             has "$out" "risky command"
t "risky fix did not run"            test -f "$FX/build/keep"
mkj "cp /nonexistent_zz /tmp/zz_out" "touch c.txt" "$W/j6.tsv"
out=$(DEJSH_JOURNAL=$W/j6.tsv pty_run "$D" fix --run | strip)
t "failing step stops the chain"     has "$out" "failed part-way"
t "later step did not run"           test ! -f "$FX/c.txt"
t "guard-check flags a secret"       test "$(printf 'export X=%s\n' "$STRIPE" | "$D" guard-check)" = "Stripe live key"
t "guard-check clears normal input"  sh -c "echo 'ls -la' | \"$D\" guard-check; [ \$? -ne 0 ]"
t "guard zsh snippet"  has "$("$D" guard zsh)"  "zshaddhistory"
t "guard bash snippet" has "$("$D" guard bash)" "history -d"
t "guard fish snippet" has "$("$D" guard fish)" "fish_should_add_to_history"
DIR_D=$(dirname "$D")
# negative control: the same session WITHOUT the guard must save the secret (proves the guard tests can fail)
if command -v zsh >/dev/null 2>&1; then
  CZ=$(mktemp -d); printf 'HISTFILE=%s/.zhist\nHISTSIZE=100\nSAVEHIST=100\n' "$CZ" > "$CZ/.zshrc"
  PTY_SECRET="$STRIPE" pty_session "$CZ" "$CZ/.config" zsh -i >/dev/null 2>&1
  t "control (zsh, no guard): secret IS saved" has "$(cat "$CZ/.zhist" 2>/dev/null)" "$STRIPE"
fi
CB=$(mktemp -d); printf 'HISTFILE=%s/.bhist\nHISTSIZE=100\nHISTFILESIZE=100\n' "$CB" > "$CB/.bashrc"
PTY_SECRET="$STRIPE" pty_session "$CB" "$CB/.config" bash --rcfile "$CB/.bashrc" -i >/dev/null 2>&1
t "control (bash, no guard): secret IS saved" has "$(cat "$CB/.bhist" 2>/dev/null)" "$STRIPE"
if command -v zsh >/dev/null 2>&1; then
  GZ=$(mktemp -d); { printf 'HISTFILE=%s/.zhist\nHISTSIZE=100\nSAVEHIST=100\nexport PATH="%s:$PATH"\n' "$GZ" "$DIR_D"; "$D" guard zsh; } > "$GZ/.zshrc"
  PTY_SECRET="$STRIPE" pty_session "$GZ" "$GZ/.config" zsh -i >/dev/null 2>&1
  hz=$(cat "$GZ/.zhist" 2>/dev/null)
  t "zsh guard keeps normal commands in history" has "$hz" "echo hello"
  t "zsh guard keeps later commands too"        has "$hz" "echo after"
  t "zsh guard kept the secret out of history"  hasnt "$hz" "$STRIPE"
fi
GB=$(mktemp -d); { printf 'HISTFILE=%s/.bhist\nHISTSIZE=100\nHISTFILESIZE=100\nexport PATH="%s:$PATH"\n' "$GB" "$DIR_D"; "$D" guard bash; } > "$GB/.bashrc"
PTY_SECRET="$STRIPE" pty_session "$GB" "$GB/.config" bash --rcfile "$GB/.bashrc" -i >/dev/null 2>&1
hb=$(cat "$GB/.bhist" 2>/dev/null)
t "bash guard keeps normal commands in history" has "$hb" "echo hello"
t "bash guard keeps later commands too"        has "$hb" "echo after"
t "bash guard kept the secret out of history"  hasnt "$hb" "$STRIPE"
if command -v fish >/dev/null 2>&1; then
  GF=$(mktemp -d); mkdir -p "$GF/.config/fish"; { printf 'set -gx PATH "%s" $PATH\n' "$DIR_D"; "$D" guard fish; } > "$GF/.config/fish/config.fish"
  PTY_SECRET="$STRIPE" pty_session "$GF" "$GF/.config" fish -i >/dev/null 2>&1
  hf=$(cat "$GF/.local/share/fish/fish_history" 2>/dev/null)
  case $hf in *"$STRIPE"*) echo "  --- fish guard diagnostics: $(fish --version)"; echo "  history tail:"; tail -6 "$GF/.local/share/fish/fish_history" 2>&1 | cut -c1-120; echo "  function defined? $(fish -c 'functions -q fish_should_add_to_history; and echo yes; or echo no' 2>&1)"; echo "  guard-check on PATH in fish? $(PATH="$DIR_D:$PATH" fish -c 'printf "x=%s\n" '"$STRIPE"' | dejsh guard-check' 2>&1 | head -2)";; esac
  t "fish guard keeps normal commands in history" has "$hf" "echo hello"
  t "fish guard kept the secret out of history"   hasnt "$hf" "$STRIPE"
fi

section "dig"
out=$("$D" dig -f "$H" -l 3 | strip); t "dig renders layers" has "$out" "surface (today)"; t "dig names eras" has "$out" "The Version Age"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
