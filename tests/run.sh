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

section "dig"
out=$("$D" dig -f "$H" -l 3 | strip); t "dig renders layers" has "$out" "surface (today)"; t "dig names eras" has "$out" "The Version Age"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
