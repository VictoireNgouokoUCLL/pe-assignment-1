#!/usr/bin/env bash
#
# Completeness check for assignment 1.
#
# This checks that the files you are supposed to hand in exist and are not
# empty. It does NOT check whether your configuration is correct, and it does
# not produce a grade. A green result only means you did not forget anything.
#
set -uo pipefail
cd "$(dirname "$0")"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS=0; FAIL=0

pass() { echo -e "${GREEN}OK${NC}   $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}MISS${NC} $1"; [ -n "${2:-}" ] && echo -e "     ${YELLOW}->${NC} $2"; FAIL=$((FAIL+1)); }

need_file() {
  if [ ! -f "$1" ]; then
    fail "$1" "${2:-}"
  elif [ ! -s "$1" ]; then
    fail "$1 is empty" "${2:-}"
  else
    pass "$1"
  fi
}

echo "Assignment 1 - completeness check"
echo "---------------------------------"

need_file "spec.md"        "run ./bin/personalise.sh"
need_file ".env"           "run ./bin/personalise.sh"

if [ -d submission/sudoers.d ] && [ -n "$(find submission/sudoers.d -type f ! -name .gitkeep 2>/dev/null)" ]; then
  pass "submission/sudoers.d/ contains at least one file"
else
  fail "submission/sudoers.d/ is empty" "copy your sudo drop-in file(s) here"
fi

need_file "submission/default-locale"    "part 1: cp /etc/default/locale /lab/submission/default-locale"
need_file "submission/sshd_hardening.conf"  "part 2"
need_file "submission/packages.txt"         "part 3: dpkg -l openssh-server sudo rsync cron chrony > submission/packages.txt"
need_file "submission/timezone"             "part 4"
need_file "submission/chrony.conf"          "part 4"
need_file "submission/backup.sh"            "part 5"
need_file "submission/crontab-service.txt"  "part 5: crontab -l for the service account"
need_file "submission/report.txt"         "part 7: run ./bin/collect-evidence.sh <your private key>"
need_file "submission/defect-raw.txt"     "part 6: the raw output that put you on the trail"
need_file "submission/defect.md"         "part 6"
need_file "submission/justification.md" "part 8"

# The two write-ups must actually have been edited.
for f in submission/defect.md submission/justification.md; do
  if [ -f "$f" ] && grep -q "TODO: replace this line" "$f"; then
    fail "$f still contains the template placeholders" "write your own text"
  fi
done

# An AI statement is required, whether or not you used one.
if [ -f submission/justification.md ] \
   && ! grep -qE '^- \*\*Which tools\*\*[^:]*:[[:space:]]*[^[:space:]]' submission/justification.md; then
  fail "no AI statement found in submission/justification.md" \
       "state which tools you used, or that you used none"
fi

# Never hand in a private key.
if git ls-files 2>/dev/null | grep -qEi '(^|/)(id_(rsa|ed25519|ecdsa)|.*\.pem|.*\.key)$'; then
  fail "a file that looks like a private key is tracked by git" \
       "remove it from the repository and rotate the key"
else
  pass "no private keys tracked by git"
fi

echo "---------------------------------"
echo "$PASS present, $FAIL missing"
if [ $FAIL -eq 0 ]; then
  echo -e "${GREEN}Everything is there.${NC} That is not the same as everything being right -"
  echo "read submission/report.txt once more before you push."
else
  echo -e "${YELLOW}Fix the items above before the deadline.${NC}"
  exit 1
fi
