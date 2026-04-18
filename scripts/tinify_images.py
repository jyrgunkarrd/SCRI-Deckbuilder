#!/usr/bin/env python3
import argparse
import base64
import getpass
import http.client
import json
import os
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path


SHRINK_URL = "https://api.tinify.com/shrink"


def parse_args():
    parser = argparse.ArgumentParser(description="Compress PNG images with the Tinify API.")
    parser.add_argument("paths", nargs="*", default=["assets/images"], help="Files or directories to process.")
    parser.add_argument("--ext", default=".png", help="Image extension to process.")
    return parser.parse_args()


def read_api_key():
    api_key = os.environ.get("TINIFY_API_KEY")
    if api_key:
        return api_key

    return getpass.getpass("Tinify API key: ")


def make_auth_header(api_key):
    token = base64.b64encode(("api:" + api_key).encode("utf-8")).decode("ascii")
    return "Basic " + token


def read_error(error):
    body = error.read().decode("utf-8", errors="replace")
    try:
        parsed = json.loads(body)
    except json.JSONDecodeError:
        return body.strip() or str(error)

    message = parsed.get("message") or body
    error_name = parsed.get("error")
    if error_name:
        return f"{error_name}: {message}"
    return message


def request_json(url, data, auth_header):
    request = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": auth_header,
            "Content-Type": "application/octet-stream",
        },
        method="POST",
    )
    return urllib.request.urlopen(request)


def download(url, auth_header):
    request = urllib.request.Request(url, headers={"Authorization": auth_header})
    return urllib.request.urlopen(request).read()


def compress(path, auth_header):
    original = path.read_bytes()
    with request_json(SHRINK_URL, original, auth_header) as response:
        output_url = response.headers["Location"]
        compression_count = response.headers.get("Compression-Count")

    compressed = download(output_url, auth_header)

    fd, temp_name = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=str(path.parent))
    try:
        with os.fdopen(fd, "wb") as temp_file:
            temp_file.write(compressed)
        os.replace(temp_name, path)
    except Exception:
        try:
            os.unlink(temp_name)
        except FileNotFoundError:
            pass
        raise

    return len(original), len(compressed), compression_count


def main():
    args = parse_args()
    extension = args.ext.lower()

    paths = []
    for raw_path in args.paths:
        path = Path(raw_path)
        if not path.exists():
            print(f"Missing path: {path}", file=sys.stderr)
            return 2
        if path.is_file():
            if path.suffix.lower() == extension:
                paths.append(path)
        else:
            paths.extend(
                child for child in path.rglob("*")
                if child.is_file() and child.suffix.lower() == extension
            )
    paths = sorted(set(paths))
    if not paths:
        print(f"No {extension} files found")
        return 0

    auth_header = make_auth_header(read_api_key())
    total_before = 0
    total_after = 0
    completed = 0

    for index, path in enumerate(paths, start=1):
        try:
            before, after, compression_count = compress(path, auth_header)
        except urllib.error.HTTPError as error:
            print(f"\nFailed: {path}", file=sys.stderr)
            print(read_error(error), file=sys.stderr)
            return 1
        except urllib.error.URLError as error:
            print(f"\nNetwork error while processing {path}: {error}", file=sys.stderr)
            return 1
        except http.client.IncompleteRead as error:
            print(f"\nIncomplete download while processing {path}: {error}", file=sys.stderr)
            return 1

        total_before += before
        total_after += after
        completed += 1
        saved = before - after
        suffix = f", API count {compression_count}" if compression_count else ""
        print(f"[{index}/{len(paths)}] {path}: {before} -> {after} bytes, saved {saved}{suffix}")

    saved_total = total_before - total_after
    print()
    print(f"Processed: {completed}")
    print(f"Before: {total_before} bytes")
    print(f"After: {total_after} bytes")
    print(f"Saved: {saved_total} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
