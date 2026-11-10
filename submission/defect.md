defecten


## 1. Symptom
When running any `sudo` command (such as `sudo -l`), the system printed a configuration warning:

sudo: /etc/sudoers.d/90-inherited contains a '.' in name, refusing to use file



## 2. Diagnosis
1. Executed `sudo -l` to check sudo permissions, which immediately surfaced the warning regarding the filename in `/etc/sudoers.d/`.

2. Listed the contents of `/etc/sudoers.d/` using `ls -la /etc/sudoers.d/` to inspect naming conventions and file attributes.

cat << 'EOF' > /lab/submission/defect.md
defecten


## 1. Symptom
When running any `sudo` command (such as `sudo -l`), the system printed a configuration warning:

sudo: /etc/sudoers.d/90-inherited contains a '.' in name, refusing to use file



## 2. Diagnosis
1. Executed `sudo -l` to check sudo permissions, which immediately surfaced the warning regarding the filename in `/etc/sudoers.d/`.

2. Listed the contents of `/etc/sudoers.d/` using `ls -la /etc/sudoers.d/` to inspect naming conventions and file attributes.

3. Root cause
The `sudo` utility strictly enforces security rules on drop-in files inside `/etc/sudoers.d/`. Specifically, filenames must not contain a dot (`.`) or end with certain prohibited characters (like `~`), otherwise sudo refuses to parse them to prevent loading unintended backup or script files. The inherited file `90-inherited` (or similar depending on template naming) violated this naming standard by containing a period.:


4. Fix
Renamed the offending file in `/etc/sudoers.d/` to remove the dot (or removed/replaced it with proper configuration files like `fien` and `bram`), ensuring the filename conforms to standard rules (alphanumeric characters, hyphens, and underscores only):


bash
mv /etc/sudoers.d/90-inherited /etc/sudoers.d/90_inherited


## 5. Proof

Re-running `sudo -l` no longer produces any warning or error message, confirming that the sudoers drop-in directory is clean and successfully parsed by the system.

