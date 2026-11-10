# Justification

## 1. SSH Keys Configuration
Administrator (`fien`) and operator (`bram`) use SSH key authentication (`authorized_keys`). Password and root logins are disabled via `/etc/ssh/sshd_config.d/sshd_hardening.conf`.

## 2. Service Account Blocking (`svc-flint`)
`svc-flint` is assigned `/usr/sbin/nologin` without SSH keys, preventing interactive logins while supporting cron backup automation.

## 3. Sudoers and Least Privilege
- **`fien`:** Full administrative sudo rights.
- **`bram`:** Restricted sudo privileges (`/usr/sbin/service`, `/usr/bin/apt-get update`).

## AI Statement
Tools used: Gemini (interactive AI assistant) for reviewing task execution order, troubleshooting Chrony commands, and grammar refinement.
