#!/usr/bin/env bash
#
# SASM Foundations - Assignment 1 - evidence collection
#
# Runs a fixed set of commands against your running server and writes the
# result to submission/report.txt. It changes nothing in your configuration
# (it only refreshes the package lists), fixes nothing and marks nothing - it
# records what your server actually looks like right now.
#
# Run it from your host (not inside the container), with the server running,
# and pass the path to your private key so it can test the SSH logins:
#
#   ./bin/collect-evidence.sh ~/.ssh/<your private key>
#
# The key never leaves your machine and is not written to the report.
#
set -uo pipefail

KEY="${1:-}"
if [ -z "$KEY" ]; then
  echo "Usage: ./bin/collect-evidence.sh <path to your private SSH key>" >&2
  echo "The key is used to test the logins from your host; it is not stored." >&2
  exit 1
fi
if [ ! -f "$KEY" ]; then
  echo "Private key '$KEY' not found." >&2
  exit 1
fi

cd "$(dirname "$0")/.."

OUT="submission/report.txt"

[ -f .env ] || { echo "No .env found. Run ./bin/personalise.sh first." >&2; exit 1; }
# shellcheck disable=SC1091
. ./.env

eval "$(bash bin/personalise.sh --env "$SASM_STUDENT" | sed 's/^/SPEC_/')"

if ! docker compose ps --status running 2>/dev/null | grep -q server; then
  echo "The server does not seem to be running. Start it with: docker compose up -d" >&2
  exit 1
fi

inside() { docker compose exec -T server bash -c "$1" 2>&1; }

section() { printf '\n\n===== %s =====\n' "$1" >> "$OUT"; }
run()     { printf '\n$ %s\n' "$1" >> "$OUT"; inside "$1" >> "$OUT"; }

mkdir -p submission
: > "$OUT"

{
  echo "SASM Foundations - Assignment 1 - evidence report"
  echo "Collected at : $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "GitHub user  : $SASM_STUDENT"
  echo "Host machine : $(uname -s) $(uname -m)"
  echo ""
  echo "Specification this server is supposed to match:"
  echo "  hostname     $SPEC_HOSTNAME"
  echo "  ssh port     $SPEC_SSH_PORT"
  echo "  admin        $SPEC_ADMIN_USER (uid $SPEC_ADMIN_UID)"
  echo "  operator     $SPEC_OPS_USER (uid $SPEC_OPS_UID)"
  echo "  service      $SPEC_SVC_USER (uid $SPEC_SVC_UID)"
  echo "  group        $SPEC_GROUP"
  echo "  timezone     $SPEC_TIMEZONE"
  echo "  locale       $SPEC_LOCALE"
  echo "  ntp pool     $SPEC_NTP_POOL"
  echo "  backup       $SPEC_BACKUP_SRC daily at $(printf '%02d:%02d' "$SPEC_BACKUP_HOUR" "$SPEC_BACKUP_MIN"), keep $SPEC_RETENTION days"
} >> "$OUT"

section "1. Identity of the server"
run "hostname"
run "cat /etc/os-release | head -2"
run "uptime"

section "2. Accounts and groups"
run "id $SPEC_ADMIN_USER"
run "id $SPEC_OPS_USER"
run "id $SPEC_SVC_USER"
run "getent group $SPEC_GROUP"
run "getent passwd $SPEC_ADMIN_USER $SPEC_OPS_USER $SPEC_SVC_USER"
run "cat /etc/default/locale"
run "locale -a"

section "3. Sudo policy"
run "ls -la /etc/sudoers.d/"
run "visudo -c"
run "sudo -l -U $SPEC_ADMIN_USER"
run "sudo -l -U $SPEC_OPS_USER"
run "sudo -l -U $SPEC_SVC_USER"

section "4. SSH"
run "ls -la /etc/ssh/sshd_config.d/"
run "sshd -T 2>&1 | grep -Ei '^(port|permitrootlogin|passwordauthentication|pubkeyauthentication|allowusers|denyusers|allowgroups|denygroups|strictmodes)|error|no hostkeys' || echo '(sshd -T produced nothing usable - is sshd configured?)'"
run "ls -ld /home/$SPEC_ADMIN_USER /home/$SPEC_ADMIN_USER/.ssh /home/$SPEC_ADMIN_USER/.ssh/authorized_keys"
run "ls -ld /home/$SPEC_OPS_USER /home/$SPEC_OPS_USER/.ssh /home/$SPEC_OPS_USER/.ssh/authorized_keys"
run "find /etc /home -xdev -perm -0002 ! -type l 2>/dev/null | grep . || echo '(no world-writable files or directories)'"
run "service ssh status"

section "5. Time"
run "date"
run "readlink -f /etc/localtime"
run "cat /etc/timezone"
run "grep -Ev '^\\s*(#|\$)' /etc/chrony/chrony.conf"
run "chronyc sources"
run "chronyc tracking"

section "6. Backup"
run "ls -ld --time-style=long-iso /backup; ls -ld --time-style=long-iso /backup/*/ 2>/dev/null || echo '(no backup directories)'"
run "for d in /backup/*/; do [ -d \"\$d\" ] || continue; printf '%s  %s files\\n' \"\$d\" \"\$(find \"\$d\" -type f | wc -l)\"; done"
run "crontab -l -u $SPEC_SVC_USER"
run "su -s /bin/sh $SPEC_SVC_USER -c 'crontab -l'"
run "service cron status"
run "ls -l /etc/cron.d/; grep -Ehv '^\\s*(#|\$)' /etc/crontab /etc/cron.d/* 2>/dev/null"
run "tail -n 20 /backup/*.log 2>/dev/null || echo '(no log file in /backup)'"
run "for s in \$(crontab -l -u $SPEC_SVC_USER 2>/dev/null | grep -Ev '^\\s*(#|\$)' | awk '{print \$6}'); do echo \"--- script cron runs: \$s\"; ls -l \"\$s\"; cat \"\$s\"; cmp -s \"\$s\" /lab/submission/backup.sh && echo '--- identical to submission/backup.sh' || echo '--- DIFFERS from submission/backup.sh'; done"

section "7. Packages"
run "dpkg -l openssh-server sudo rsync cron chrony | tail -8"
run "ls -l /etc/apt/sources.list.d/; cat /etc/apt/sources.list 2>/dev/null; for f in /etc/apt/sources.list.d/*; do echo \"--- \$f\"; cat \"\$f\"; done"
run "apt-get update 2>&1 | grep -Ei '^(E:|W:|Err)' || echo '(no errors or warnings from apt-get update)'"

section "8. Running services"
run "if ! command -v ps >/dev/null; then echo '(ps not available - install procps)'; else ps -eo user,pid,stat,comm | grep -E ' (sshd|cron|chronyd)\$' | grep -v ' Z' || echo '(none of sshd, cron, chronyd is running)'; fi"

section "9. SSH logins from the host"
{
  if [ -z "$KEY" ]; then
    printf '\n(no private key given - run ./bin/collect-evidence.sh <path to your private key>)\n'
  else
    SSHO=(-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no
          -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -p "$SPEC_SSH_PORT")
    for u in "$SPEC_ADMIN_USER" "$SPEC_OPS_USER" root "$SPEC_SVC_USER"; do
      printf '\n$ ssh -i <key> -p %s %s@localhost id\n' "$SPEC_SSH_PORT" "$u"
      ssh -i "$KEY" -o IdentitiesOnly=yes "${SSHO[@]}" "$u@localhost" 'LC_ALL=C id' 2>&1 | head -3
    done
    printf '\n$ ssh -o PubkeyAuthentication=no -p %s %s@localhost id   (password only)\n' "$SPEC_SSH_PORT" "$SPEC_ADMIN_USER"
    ssh -o PubkeyAuthentication=no "${SSHO[@]}" "$SPEC_ADMIN_USER@localhost" 'LC_ALL=C id' 2>&1 | head -3
  fi
} >> "$OUT"

section "10. Repository state (collected on the host)"
{
  printf '\n$ git log --oneline\n'
  git log --oneline 2>&1 | head -40
  printf '\n$ git log --pretty=format:"%%ad %%s" --date=short\n'
  git log --pretty=format:'%ad %s' --date=short 2>&1 | head -40
  printf '\n\n$ git status --short\n'
  git status --short 2>&1 | head -40
  printf '\n$ files that look like private keys (should be empty)\n'
  git ls-files | grep -Ei '(^|/)(id_(rsa|ed25519|ecdsa)|.*\.pem|.*\.key)$' || echo "none"
} >> "$OUT"

printf '\n\n===== end of report =====\n' >> "$OUT"

echo "Wrote $OUT ($(wc -l < "$OUT") lines)."
echo ""
echo "Read it before you hand it in. Anything in there that is not what you"
echo "expected is a finding - deal with it now."
