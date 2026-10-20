# Assignment 1 — Take over a server

**Modules 1–5 · 3 of the 20 points · deadline Sunday 15 November 2026, 23:59**

---

## The situation

The previous administrator of your server left without a handover. You get the
running machine and a written specification of how it is supposed to be
configured. Your job is to bring it in line with that specification, and to
repair the one thing that is already wrong with it.

Your specification is in `spec.md`. Generate it first:

```bash
./bin/personalise.sh
cat spec.md
```

Then start the server:

```bash
docker compose up -d
docker compose exec server bash
```

Your repository is available inside the container as `/lab`. Everything you
hand in goes in `submission/`: whatever you copy to `/lab/submission/` inside
the container lands in the `submission/` folder of your repository.

> ⚠️ **Use `stop`, not `down`.** Everything you configure lives inside the
> container. `docker compose stop` / `start` preserves it. `docker compose down`
> throws it away and you start from an untouched server again — including the
> fault. Only your repository (`/lab`) and `/backup` survive a `down`.

> ⚠️ **After every `docker compose start`, nothing is running.** There is no
> systemd in the container: `sshd`, `cron` and `chronyd` are gone after a
> restart, while their configuration is still there. `crontab -l` still shows
> your line, but the backup silently never runs. Start them again before you
> test anything or collect your evidence: `service ssh start`,
> `service cron start`, and for chrony first `rm -f /run/chrony/chronyd.pid`,
> then `chronyd -x`. Your repairs survive a stop/start; only `down` undoes them.

Budget about **6 to 8 hours**. That is deliberate: this is more than a lab and
less than a project.

---

## Part 1 — Accounts, privileges and locale *(module 3)*

Create the shared group and the three accounts from `spec.md`, with exactly
the names and UIDs listed there (the group's GID is up to you). Use a plain
`useradd -m` with the UID and shell you need, not `useradd -r`: these UIDs are
in the normal user range.

| Account | Requirement |
|---|---|
| administrator | member of the shared group; may run **any** command through `sudo` |
| operator | member of the shared group; may run **only** `/usr/sbin/service` and `/usr/bin/apt-get update` through `sudo`, and nothing else |
| service account | **no** interactive login shell, **no** `sudo` rights at all; it exists to own the backup job |

Rules:

- Put your `sudo` rules in `/etc/sudoers.d/`, never by editing `/etc/sudoers`.
- Validate every file you write there with `visudo -c` before you rely on it.
- Prove the operator restriction is real: show a command that is allowed and a
  command that is refused, run *as the operator* (`su - <operator>`).
- `sudo` asks for the account's **own** password, and new accounts have none.
  Give the administrator and the operator a password with `passwd`. SSH stays
  key-only, so that password is only ever used by `sudo`.

Set the system's default locale to the one in `spec.md`, the scriptable way
from module 3: install `locales`, uncomment your locale in `/etc/locale.gen`,
then `locale-gen` and `update-locale`.

**Hand in:** your sudoers drop-in file(s) and the default locale:

```bash
cp /etc/sudoers.d/<file> /lab/submission/sudoers.d/
chmod 644 /lab/submission/sudoers.d/*
cp /etc/default/locale /lab/submission/default-locale
```

The `chmod` is for the *copy* only, so that git on your laptop can read it.
Leave the real file in `/etc/sudoers.d/` at `0440`.

---

## Part 2 — Remote access *(module 2)*

Make the server reachable over SSH, hardened to the standard from module 2.

The SSH port in `spec.md` is the port **on your host machine**. Docker forwards
it to port 22 inside the container, so `sshd` itself keeps listening on 22: do
not change `Port` in the server configuration, or the forwarding breaks. From
your host you connect with `ssh -p <your port> <user>@localhost`.

| Requirement |
|---|
| The administrator logs in with a **key**, without a password prompt |
| The operator can log in as well |
| `root` cannot log in over SSH at all |
| Password authentication is refused for everyone |
| The service account cannot log in over SSH |

Two things to think about, because they come back in the marking:

- Your key pair is generated on **your own machine**, not on the server. Say in
  your justification which half goes where, and why that direction matters.
- The service account can be blocked in two independent ways: through its shell
  and through the SSH configuration. Decide which one you rely on, and say why.

Getting your key onto the server: password login is (or will be) off and the
new accounts have no SSH password, so `ssh-copy-id` will not work. Put your
**public** key into `/home/<user>/.ssh/authorized_keys` of the administrator
**and** the operator, from inside the container (`docker compose exec server bash`),
with the ownership and permissions from module 2. Use the same key pair for
both: the evidence script in part 7 logs in as both with that one key.
Before you change anything in a new home directory, look at what `useradd -m`
already put there (`ls -la`) and ask yourself where it came from: on a server
you inherited, "I fixed it for my account" is not the same as "it is fixed".

Tools for when a login is refused and the client only says
`Permission denied (publickey)`:

- `sshd -t` checks the configuration for errors; `sshd -T` prints the
  configuration sshd *actually* uses, with every file in
  `/etc/ssh/sshd_config.d/` merged in. Compare it with what you think you wrote.
  Both need `/run/sshd`, which `service ssh start` creates: before the first
  start they complain *Missing privilege separation directory*.
- The server knows why it refused you; the client is never told. Run sshd in
  the foreground in debug mode: `service ssh stop`, then `/usr/sbin/sshd -d`
  in the container, and log in once from your host **in a second terminal**.
  The server prints its reasoning and exits. Start the service again afterwards
  with `service ssh start`.

**Hand in:** `submission/sshd_hardening.conf` — your drop-in from
`/etc/ssh/sshd_config.d/`, copied to `/lab/submission/`.

---

## Part 3 — Packages *(module 4)*

Bring the package state in order: the package lists must refresh without errors,
the system must be upgraded, and the packages you need must be installed (at
minimum `openssh-server`, `sudo`, `rsync`, `cron`, `chrony`). You will also want
`procps` (for `ps`), `man-db` (for `man`) and an editor such as `nano`.

**Hand in:** `submission/packages.txt` — the output of
`dpkg -l openssh-server sudo rsync cron chrony > /lab/submission/packages.txt`.

---

## Part 4 — Time *(module 5)*

- Set the timezone from `spec.md`, and make sure `/etc/localtime` and
  `/etc/timezone` agree with each other.
- Configure `chrony` to use the NTP pool from `spec.md`, and get it running
  the way you did in module 5, with `chronyd -x` (it cannot set the clock in a
  container).
  `chronyc tracking` must show a selected source when you collect your
  evidence.

Reminders from module 5:

- `service chrony start` fails in a container and leaves `/run/chrony/chronyd.pid`
  behind. Remove it before you start chronyd again, or it refuses with
  *Another chronyd may already be running*.
- Right after starting, `chronyc sources` is still empty. Wait until one line
  shows `^*`.
- Changing the timezone while cron is running makes cron skip the next run of a
  fixed-time job. Restart cron after you change the timezone.

**Hand in:** `submission/timezone`, `submission/chrony.conf`
(`cp /etc/timezone /etc/chrony/chrony.conf /lab/submission/`).

---

## Part 5 — Backup *(module 5)*

Write `backup.sh`, which:

1. copies the directory named in `spec.md` to `/backup/` with `rsync`;
2. writes each run into its own dated directory;
3. deletes backup directories older than the retention period in `spec.md`;
4. runs **as the service account**, daily, at the time in `spec.md`.

If the directory to back up does not exist yet, create it and put at least three
files in it — an empty backup proves nothing.

Run it at least twice, and prove your retention logic actually removes
something. You do not have to wait days for that: think about how you could
create a backup directory that *looks* old.

Hints:

- Put the script in a fixed place on the server, for example
  `/usr/local/bin/backup.sh`, and point cron at that path. Hand in a copy.
- `/backup` belongs to root. The service account has to be able to write there.
- The service account has no login shell, so `su - <account>` will not work.
  `su -s /bin/bash <account>` starts a shell for it anyway; from there,
  `crontab -e` edits *its* crontab. Run the backup by hand as that account at
  least once: a script that works as root can fail as somebody else.
- As a normal account, `rsync` cannot read everything (in `/etc` for example
  `/etc/shadow`). It then copies what it can and exits with code 23. Decide how
  your script deals with that, and make sure the clean-up still runs.
- `find` can select by age (`-mtime`) and act on what it finds; `touch -d`
  can give a file or directory any timestamp you like. `find --help`,
  `touch --help`, or `man find` once `man-db` is installed. Note that
  `-mtime +N` means *more than N whole days*: decide what "keep N days" means
  for you, and say so in a comment in your script.
- Test the deletion part with `-print` before you let it delete anything.
- Let the script append what it did, including what it deleted, to a log file
  in `/backup` (for example `/backup/backup.log`). The evidence report shows the
  end of that log: that is how a marker sees your retention working.
- `rsync -a` copies the source's modification time onto your new dated
  directory. If the source is old, your brand-new backup *looks* old to `find`
  and your own clean-up deletes it. Check with `ls -ld` and fix it in your
  script.

**Hand in:** `submission/backup.sh`, `submission/crontab-service.txt` (the output of
`crontab -l` for the service account, saved to `/lab/submission/`).

---

## Part 6 — The fault you inherited

Exactly one thing about this server was already wrong when you received it. It
will get in your way at some point while you work through parts 1 to 5, as long
as you check your work after every part instead of only at the end. It does not
always show up as an error message: read what your tools, and later your
`report.txt`, tell you about the server, not only whether your own commands
succeeded.

Write it up in `submission/defect.md`:

1. **Symptom** — what did you see that was not right? Quote the actual output.
2. **Diagnosis** — how did you narrow it down? Which commands, in which order,
   and what did each one show you?
3. **Root cause** — what exactly was wrong, and why did it produce that symptom?
4. **Fix** — what did you change?
5. **Proof** — how do you know it is fixed?

Save the raw output that first put you on the trail in
`submission/defect-raw.txt` (inside the container: `/lab/submission/defect-raw.txt`).
Paste it unedited.

> The marks are in steps 3 to 5: the **root cause**, not just the symptom, a fix
> **at that cause**, so the fault cannot come back, and proof that shows up in
> your `report.txt`. A long story does not earn more than a short, correct one.

---

## Part 7 — Evidence

From your **host** (not inside the container), with the server and its
services running (`sshd`, `cron`, and `chronyd` with a `^*` line in
`chronyc sources`), and with the path to your **private** key:

```bash
./bin/collect-evidence.sh ~/.ssh/<your private key>
```

This runs a fixed set of commands against your server, tries the SSH logins
from your host with that key, and writes `submission/report.txt`. It changes
nothing in your configuration (it only refreshes the package lists), it does
not fix anything and it does not mark anything. The key itself never leaves
your machine and is not written to the report.

Read the report before you hand it in. If something in it is not what you
expected, that is a finding — deal with it now rather than in January.

---

## Part 8 — Justification

In `submission/justification.md`, about **400 words in total**:

- **Three choices you made**, each with your reasoning. Not "I ran this
  command", but why that approach and not an obvious alternative. The two
  questions in part 2 are good candidates.
- **Your AI statement.** Which tools you used, what you asked them, what came
  back, and what you changed about it. If you used none, write that.

In your own words. It is short on purpose.

---

## Working method *(module 4)*

Your git history is part of the assessment. Commit as you go: at least three
commits with messages that say what changed and why. One commit containing
everything on the evening of the deadline scores the lowest band on this
criterion.

Never commit a private key, a password or a `.pem` file.

---

## Before you push

On your laptop, in the repository folder:

```bash
./check.sh
git add submission/ spec.md .env && git commit -m "assignment 1: <what you did>" && git push
```

Add exactly these paths, not `git add -A` or `git add .`: that is how private
keys and stray files end up in a repository.

`check.sh` verifies that the expected files exist and are not empty. It does not
look at whether your content is correct, and passing it is not a grade — it only
stops you from losing points over a file you forgot.

---

## How this is marked

Six criteria, each scored 0, 1 or 2 — twelve points, converted to your 3.

| | Criterion |
|---|---|
| 1 | Accounts, group membership, sudo policy and locale match the specification |
| 2 | SSH hardened as specified and demonstrably working |
| 3 | Time configuration and backup with retention, correctly scheduled |
| 4 | Evidence matches your specification; the fault's root cause is found and fixed at the source |
| 5 | Three choices defended in your own words, AI statement present |
| 6 | Meaningful commits spread over time, package state in order, no secrets in the repository |

The full rubric is on Toledo.
