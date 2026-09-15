import urllib.request
import urllib.error
import ssl
import json
import os
import datetime
import argparse
import sys
import re

def parse_duration(duration_str):
    """
    Parses duration strings like '2h', '1.5hr', '1h 30m', '45 min', '30m' into milliseconds.
    """
    duration_str = str(duration_str).strip().lower()
    
    # Try parsing pure numeric inputs as hours
    try:
        val = float(duration_str)
        return int(val * 60 * 60 * 1000)
    except ValueError:
        pass

    total_ms = 0
    # Match hours
    hours_match = re.search(r'([\d.]+)\s*(h|hr|hour|hrs|hours)', duration_str)
    if hours_match:
        total_ms += float(hours_match.group(1)) * 60 * 60 * 1000
    
    # Match minutes
    minutes_match = re.search(r'([\d.]+)\s*(m|min|minute|mins|minutes)', duration_str)
    if minutes_match:
        total_ms += float(minutes_match.group(1)) * 60 * 1000
        
    # If no match but contains digits, check if it was just minutes or hours
    if total_ms == 0:
        digits_match = re.findall(r'[\d.]+', duration_str)
        if digits_match:
            # Default to hours if it's a small number, otherwise minutes
            val = float(digits_match[0])
            if val < 24:
                total_ms = int(val * 60 * 60 * 1000)
            else:
                total_ms = int(val * 60 * 1000)
                
    if total_ms == 0:
        raise ValueError(f"Could not parse duration: {duration_str}")
        
    return int(total_ms)

def get_team_id(api_key, context):
    """
    Fetches the first workspace/team ID for the user.
    """
    url = "https://api.clickup.com/api/v2/team"
    req = urllib.request.Request(url, headers={"Authorization": api_key})
    try:
        with urllib.request.urlopen(req, context=context) as response:
            data = json.loads(response.read().decode('utf-8'))
            teams = data.get('teams', [])
            if teams:
                return teams[0]['id']
    except Exception as e:
        print("Warning: Could not fetch team_id automatically:", e)
    return "2703127" # Default fallback

def log_time_entry(api_key, team_id, start_ms, tid, description, duration_ms, context):
    """
    Logs a single time entry via ClickUp API.
    """
    url = f"https://api.clickup.com/api/v2/team/{team_id}/time_entries"
    payload = {
        "start": start_ms,
        "duration": duration_ms,
        "tid": tid,
        "description": description
    }
    
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode('utf-8'),
        headers={
            "Authorization": api_key,
            "Content-Type": "application/json"
        },
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req, context=context) as response:
            res_data = json.loads(response.read().decode('utf-8'))
            return res_data.get("data", {}).get("id")
    except urllib.error.HTTPError as e:
        error_msg = e.read().decode('utf-8', errors='ignore')
        raise Exception(f"HTTP Error {e.code}: {e.reason}\nResponse: {error_msg}")
    except Exception as e:
        raise Exception(f"Error: {e}")

def main():
    parser = argparse.ArgumentParser(description="Reusable ClickUp Time Entry Logger")
    parser.add_argument("--date", help="Date of entry (YYYY-MM-DD), default is today")
    parser.add_argument("--tid", help="Task ID (for single entry mode)")
    parser.add_argument("--desc", help="Description of entry (for single entry mode)")
    parser.add_argument("--duration", help="Duration of entry e.g. '2.5h', '30m' (for single entry mode)")
    parser.add_argument("--team-id", help="ClickUp Team ID/Workspace ID")
    parser.add_argument("--json", help="JSON string containing multiple entries")
    parser.add_argument("--file", help="Path to JSON file containing entries")
    
    args = parser.parse_args()
    
    api_key = os.environ.get("CLICKUP_API_KEY")
    if not api_key:
        # Fallback: read from ~/.clickup_credentials (chmod 600, never tracked by git)
        creds_path = os.path.expanduser("~/.clickup_credentials")
        if os.path.exists(creds_path):
            with open(creds_path, "r") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("CLICKUP_API_KEY="):
                        api_key = line.split("=", 1)[1].strip()
                        break
    if not api_key:
        print("Error: CLICKUP_API_KEY not found in environment or ~/.clickup_credentials.", file=sys.stderr)
        sys.exit(1)
        
    context = ssl._create_unverified_context()
    
    # Resolve team ID
    team_id = args.team_id or get_team_id(api_key, context)
    
    # Determine the date (default is today)
    tz_ist = datetime.timezone(datetime.timedelta(hours=5, minutes=30))
    if args.date:
        parts = list(map(int, args.date.split('-')))
        target_date = datetime.date(parts[0], parts[1], parts[2])
    else:
        target_date = datetime.datetime.now(tz=tz_ist).date()
        
    # Start time defaults to 09:00:00 AM local time
    start_dt = datetime.datetime(target_date.year, target_date.month, target_date.day, 9, 0, 0, tzinfo=tz_ist)
    start_ms = int(start_dt.timestamp() * 1000)
    
    entries = []
    
    # Prioritize --file first, then --json
    if args.file:
        try:
            with open(args.file, "r") as f:
                payload = json.load(f)
            if isinstance(payload, dict):
                if "date" in payload and not args.date:
                    parts = list(map(int, payload["date"].split('-')))
                    target_date = datetime.date(parts[0], parts[1], parts[2])
                    start_dt = datetime.datetime(target_date.year, target_date.month, target_date.day, 9, 0, 0, tzinfo=tz_ist)
                    start_ms = int(start_dt.timestamp() * 1000)
                entries = payload.get("entries", [])
            elif isinstance(payload, list):
                entries = payload
        except Exception as e:
            print(f"Error loading JSON file: {e}", file=sys.stderr)
            sys.exit(1)
    elif args.json:
        try:
            payload = json.loads(args.json)
            if isinstance(payload, dict):
                if "date" in payload and not args.date:
                    parts = list(map(int, payload["date"].split('-')))
                    target_date = datetime.date(parts[0], parts[1], parts[2])
                    start_dt = datetime.datetime(target_date.year, target_date.month, target_date.day, 9, 0, 0, tzinfo=tz_ist)
                    start_ms = int(start_dt.timestamp() * 1000)
                entries = payload.get("entries", [])
            elif isinstance(payload, list):
                entries = payload
        except Exception as e:
            print(f"Error parsing JSON argument: {e}", file=sys.stderr)
            sys.exit(1)
    # Stdin fallback only if stdin is not a tty and actually has data
    elif not sys.stdin.isatty():
        try:
            # Check if there is data in stdin (non-blocking)
            import select
            if select.select([sys.stdin], [], [], 0.0)[0]:
                stdin_data = sys.stdin.read().strip()
                if stdin_data:
                    payload = json.loads(stdin_data)
                    if isinstance(payload, dict):
                        if "date" in payload and not args.date:
                            parts = list(map(int, payload["date"].split('-')))
                            target_date = datetime.date(parts[0], parts[1], parts[2])
                            start_dt = datetime.datetime(target_date.year, target_date.month, target_date.day, 9, 0, 0, tzinfo=tz_ist)
                            start_ms = int(start_dt.timestamp() * 1000)
                        entries = payload.get("entries", [])
                    elif isinstance(payload, list):
                        entries = payload
        except Exception as e:
            print(f"Error parsing JSON from stdin: {e}", file=sys.stderr)
            sys.exit(1)
            
    # Single entry mode fallback
    if not entries:
        if not args.tid or not args.duration:
            parser.print_help()
            sys.exit(1)
        entries = [{
            "tid": args.tid,
            "description": args.desc or "",
            "duration": args.duration
        }]
        
    print(f"Logging time entries for {target_date.isoformat()} (Workspace: {team_id})...")
    
    success_count = 0
    for i, entry in enumerate(entries, 1):
        tid = entry.get("tid")
        desc = entry.get("description", "")
        dur_str = entry.get("duration")
        
        try:
            dur_ms = parse_duration(dur_str)
            print(f"\n[{i}/{len(entries)}] Logging {dur_str} on task {tid}...")
            entry_id = log_time_entry(api_key, team_id, start_ms, tid, desc, dur_ms, context)
            print(f"Success! Time Entry ID: {entry_id}")
            success_count += 1
        except Exception as e:
            print(f"Failed to log entry: {e}", file=sys.stderr)
            
    print(f"\nCompleted: {success_count}/{len(entries)} entries logged successfully.")

if __name__ == "__main__":
    main()
