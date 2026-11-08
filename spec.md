# Your server specification

Generated for GitHub user **template**. These values are yours; your
neighbour's are different. Every requirement below is checked against exactly
these values, so copy them carefully.

| Setting | Your value |
|---|---|
| Server hostname | `srv-mistral-52` |
| SSH port (on your host machine) | `2319` |
| Administrator account | `cato`, UID `1531` |
| Operator account | `ruben`, UID `1645` |
| Service account | `svc-ember`, UID `1728` |
| Shared group | `pallasops` |
| Timezone | `Europe/Brussels` |
| System locale | `fr_BE.UTF-8` |
| NTP pool | `europe.pool.ntp.org` |
| Directory to back up | `/etc` |
| Backup runs daily at | `03:10` |
| Keep backups for | `12` days |

Cron expression for that schedule, if you want to check your own: the minute
field is `10` and the hour field is `3`.

> Re-running `./bin/personalise.sh` always produces this same table. If your
> values ever change, you ran it with a different username.
