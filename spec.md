# Your server specification

Generated for GitHub user ****. These values are yours; your
neighbour's are different. Every requirement below is checked against exactly
these values, so copy them carefully.

| Setting | Your value |
|---|---|
| Server hostname | `srv-delta-96` |
| SSH port (on your host machine) | `2311` |
| Administrator account | `cato`, UID `1528` |
| Operator account | `ruben`, UID `1620` |
| Service account | `svc-mistral`, UID `1774` |
| Shared group | `emberops` |
| Timezone | `Asia/Tokyo` |
| System locale | `en_US.UTF-8` |
| NTP pool | `nl.pool.ntp.org` |
| Directory to back up | `/etc` |
| Backup runs daily at | `01:00` |
| Keep backups for | `6` days |

Cron expression for that schedule, if you want to check your own: the minute
field is `0` and the hour field is `1`.

> Re-running `./bin/personalise.sh` always produces this same table. If your
> values ever change, you ran it with a different username.
