"""Headless scheduler for Railway deployment.

Reads schedule configuration from the SCHEDULE_JOBS environment variable,
a JSON array of job definitions. Each job specifies a platform, account ID,
and scheduling interval.

Example SCHEDULE_JOBS value:
[
  {
    "platform": "youtube",
    "account_id": "550e8400-e29b-41d4-a716-446655440000",
    "interval": "daily",
    "times": ["10:00", "16:00"]
  },
  {
    "platform": "twitter",
    "account_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
    "interval": "daily",
    "times": ["08:00", "12:00", "18:00"]
  }
]

Interval options:
  - "daily"              -> runs at each specified time (HH:MM)
  - "every_N_hours"      -> runs every N hours
  - "every_N_minutes"    -> runs every N minutes
"""

import os
import sys
import json
import time
import subprocess

import schedule

from config import ROOT_DIR, get_ollama_model
from status import info, success, error, warning


def load_jobs():
    """Load job definitions from the SCHEDULE_JOBS environment variable."""
    jobs_json = os.environ.get("SCHEDULE_JOBS", "[]")
    try:
        jobs = json.loads(jobs_json)
    except json.JSONDecodeError as e:
        error(f"Failed to parse SCHEDULE_JOBS: {e}")
        sys.exit(1)
    return jobs


def make_runner(platform, account_id, model):
    """Create a callable that runs cron.py for the given platform and account."""
    cron_script = os.path.join(ROOT_DIR, "src", "cron.py")
    command = ["python", cron_script, platform, account_id, model]

    def run():
        info(f"[scheduler] Running: {platform} for account {account_id}")
        try:
            result = subprocess.run(command, timeout=1800)
            if result.returncode == 0:
                success(f"[scheduler] Completed: {platform} for {account_id}")
            else:
                error(f"[scheduler] Failed with code {result.returncode}: {platform} for {account_id}")
        except subprocess.TimeoutExpired:
            error(f"[scheduler] Timed out: {platform} for {account_id}")
        except Exception as e:
            error(f"[scheduler] Error: {e}")

    return run


def main():
    model = get_ollama_model() or os.environ.get("OLLAMA_MODEL", "llama3.2:3b")
    jobs = load_jobs()

    if not jobs:
        warning("[scheduler] No jobs configured. Set SCHEDULE_JOBS env var.")
        warning("[scheduler] Sleeping indefinitely to keep container alive...")
        while True:
            time.sleep(3600)

    for job_def in jobs:
        platform = job_def["platform"]
        account_id = job_def["account_id"]
        interval = job_def.get("interval", "daily")
        times = job_def.get("times", ["10:00"])

        runner = make_runner(platform, account_id, model)

        if interval == "daily":
            for t in times:
                schedule.every().day.at(t).do(runner)
                info(f"[scheduler] Scheduled {platform}/{account_id} daily at {t}")
        elif interval.startswith("every_") and interval.endswith("_hours"):
            n = int(interval.split("_")[1])
            schedule.every(n).hours.do(runner)
            info(f"[scheduler] Scheduled {platform}/{account_id} every {n} hours")
        elif interval.startswith("every_") and interval.endswith("_minutes"):
            n = int(interval.split("_")[1])
            schedule.every(n).minutes.do(runner)
            info(f"[scheduler] Scheduled {platform}/{account_id} every {n} minutes")
        else:
            error(f"[scheduler] Unknown interval '{interval}' for {platform}/{account_id}")

    info(f"[scheduler] {len(schedule.get_jobs())} job(s) scheduled. Entering run loop...")

    while True:
        schedule.run_pending()
        time.sleep(30)


if __name__ == "__main__":
    main()
