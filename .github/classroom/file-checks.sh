#!/usr/bin/env bash
#
# Assignment 1 - progress signal for the lecturer (GitHub Actions).
#
# This is NOT the grade. It reports whether the expected files exist and whether
# the personalised specification in the repository still matches the one derived
# from the student's username.
#
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}OK${NC}   $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}MISS${NC} $1"; [ -n "${2:-}" ] && echo -e "     ${YELLOW}->${NC} $2"; FAIL=$((FAIL+1)); }

need() {
  if [ -f "$1" ] && [ -s "$1" ]; then pass "$1"; else fail "$1" "${2:-}"; fi
}

echo "== files =="
need spec.md
need .env
need submission/default-locale
need submission/sshd_hardening.conf
need submission/packages.txt
need submission/timezone
need submission/chrony.conf
need submission/backup.sh
need submission/crontab-service.txt
need submission/report.txt
need submission/defect-raw.txt
need submission/defect.md
need submission/justification.md

if [ -d submission/sudoers.d ] && [ -n "$(find submission/sudoers.d -type f ! -name .gitkeep 2>/dev/null)" ]; then
  pass "submission/sudoers.d/ not empty"
else
  fail "submission/sudoers.d/ empty"
fi

echo ""
echo "== specification consistency =="
# The repository is called [<classroom>-]pe-assignment-1-<username>; derive the username from it
# and regenerate the specification. If it differs from what is committed, the
# .env or spec.md in the repository was edited by hand.
REPO="${GITHUB_REPOSITORY##*/}"
STUDENT="${REPO##*pe-assignment-1-}"

if [ "$STUDENT" = "$REPO" ]; then
  echo "could not derive the username from '$REPO' - skipping this check"
elif [ ! -f .env ]; then
  fail ".env missing" "cannot verify the specification"
else
  EXPECTED="$(bash bin/personalise.sh --env "$STUDENT")"
  COMMITTED_HOST="$(grep '^SASM_HOSTNAME=' .env | cut -d= -f2-)"
  COMMITTED_PORT="$(grep '^SASM_SSH_PORT=' .env | cut -d= -f2-)"
  EXPECTED_HOST="$(printf '%s\n' "$EXPECTED" | grep '^HOSTNAME=' | cut -d= -f2-)"
  EXPECTED_PORT="$(printf '%s\n' "$EXPECTED" | grep '^SSH_PORT=' | cut -d= -f2-)"

  if [ "$COMMITTED_HOST" = "$EXPECTED_HOST" ] && [ "$COMMITTED_PORT" = "$EXPECTED_PORT" ]; then
    pass "committed .env matches the specification for '$STUDENT'"
  else
    fail "committed .env does not match the specification for '$STUDENT'" \
         "expected $EXPECTED_HOST:$EXPECTED_PORT, found $COMMITTED_HOST:$COMMITTED_PORT - rerun ./bin/personalise.sh"
  fi

  if [ -f spec.md ] && grep -q "$EXPECTED_HOST" spec.md; then
    pass "spec.md matches the specification"
  else
    fail "spec.md does not match the specification" "rerun ./bin/personalise.sh"
  fi
fi

echo ""
echo "== hygiene =="
if git ls-files | grep -qEi '(^|/)(id_(rsa|ed25519|ecdsa)|.*\.pem|.*\.key)$'; then
  fail "a tracked file looks like a private key" "remove it and rotate the key"
else
  pass "no private keys tracked"
fi

COMMITS="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
echo "commits on this branch: $COMMITS"

echo ""
echo "--------------------------------"
echo "Result: $PASS present, $FAIL missing"
echo "This is a progress signal, not a grade. The rubric decides the marks."
