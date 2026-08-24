#!/usr/bin/env python3
"""Upload a signed .aab straight to one or more Play Console tracks
via the Android Publisher API -- no manual web upload.

This is the merge of what used to be three copies. birradar's could
update several tracks in one edit; sanlo's and coldsleep's knew how to
survive Play's flip-flopping on `changesNotSentForReview` and could
submit for review. No copy had both, which is the whole reason this
repo exists. Both features are here.

Usage (normally through an app's dev/publish-to-store.sh wrapper):
    upload_play_release.py --aab path/to/app-X.Y.Z.aab \
        --package-name com.example.app
    upload_play_release.py --aab ... --track internal --track alpha --yes
    upload_play_release.py --aab ... --track production \
        --status draft --release-notes "Fixes." --send-for-review

Requires the app repo's admin/play-service-account.json (git-crypt
encrypted, same treatment as the upload keystore). Install deps once:
    pip install -r requirements-play.txt
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def _app_repo_root() -> Path:
    """The consuming app's repo root.

    This script no longer lives in the app, so it cannot derive the
    root from its own location -- that would land in udlib's checkout
    inside pub's cache. The wrapper exports APP_REPO_ROOT; the cwd
    fallback is for running it by hand from an app checkout.
    """
    return Path(os.environ.get("APP_REPO_ROOT", ".")).resolve()


def _default_key_file() -> Path:
    """The service-account JSON that talks to the Play API.

    ONE service account serves all three apps: the Google Cloud
    project is linked to the developer ACCOUNT, and access is then
    granted per app in Play Console. No new key needs creating -- just
    grant `aab-uploader@...` access to the app under Users and
    permissions.

    So: prefer a copy in this repo if there is one (git-crypt
    encrypted, see .gitattributes), otherwise borrow birradar's from a
    sibling checkout. Not copied by default on purpose -- one
    credential in two places is one more place to leak it from.
    """
    root = _app_repo_root()
    here = root / "admin" / "play-service-account.json"
    if here.exists():
        return here
    return root.parent / "birradar" / "admin" / "play-service-account.json"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument(
        "--aab", required=True, type=Path, help="Signed .aab to upload"
    )
    p.add_argument(
        "--package-name",
        required=True,
        help="Android applicationId, e.g. com.example.app. Required: "
        "shared tooling cannot guess it, and defaulting to one app's "
        "id would make a wrong upload a typo away.",
    )
    p.add_argument(
        "--track",
        action="append",
        help="Track to update; repeat for multiple tracks. Accepts "
        "internal/alpha/beta/production or a custom track name "
        "(default: internal)",
    )
    p.add_argument(
        "--status",
        default="completed",
        choices=["completed", "draft", "halted", "inProgress"],
        help="completed = live immediately on these tracks (default)",
    )
    p.add_argument(
        "--release-notes",
        default=None,
        help="Optional release notes",
    )
    p.add_argument(
        "--release-notes-language",
        default="es-ES",
        help="BCP-47 tag the notes are written in (default: es-ES; "
        "all three apps ship Spanish first)",
    )
    p.add_argument(
        "--key-file",
        default=None,
        type=Path,
        help="Service account JSON key (default: the app's "
        "admin/play-service-account.json, else birradar's)",
    )
    p.add_argument(
        "--yes",
        action="store_true",
        help="Skip the confirmation prompt before committing",
    )
    p.add_argument(
        "--send-for-review",
        action="store_true",
        help="Submit this edit for Play's policy review on commit. "
        "Default is NOT to: the API now rejects a bare commit outright "
        "unless told explicitly either way (`changesNotSentForReview`), "
        "and defaulting to 'don't submit' matches how this script is "
        "actually used -- internal testing needs no review at all, and "
        "even a production push should not silently kick off a review "
        "of a just-rejected app unless that is exactly what's intended.",
    )
    return p.parse_args()


def main() -> int:
    # Line-buffer stdout so it interleaves with stderr in the order
    # things actually happened.
    #
    # Without this, a piped run (which is how the app wrappers are
    # normally read, and how CI captures them) shows the whole plan
    # block AFTER an error from the API: stderr is unbuffered, stdout
    # is block-buffered into a pipe and only flushes at exit. A failed
    # upload therefore ended with a tidy summary under the error,
    # which reads as a result rather than as the plan it is -- see the
    # label below, which used to make that misreading worse.
    sys.stdout.reconfigure(line_buffering=True)

    args = parse_args()
    # dict.fromkeys, not set(): de-duplicates but keeps the order the
    # tracks were given, so the printed plan matches what was asked.
    tracks = list(dict.fromkeys(args.track or ["internal"]))
    key_file = args.key_file or _default_key_file()

    if not args.aab.is_file():
        print(f"error: {args.aab} not found", file=sys.stderr)
        return 1
    if not key_file.is_file():
        print(
            f"error: service account key not found at {key_file}\n"
            "  See the app's Play Store runbook for where it comes "
            "from, or pass --key-file.",
            file=sys.stderr,
        )
        return 1

    creds = service_account.Credentials.from_service_account_file(
        str(key_file), scopes=SCOPES
    )
    service = build("androidpublisher", "v3", credentials=creds)
    edits = service.edits()

    # "Status: completed" was the old wording, and it was a trap: it
    # is Play's RELEASE status for the tracks below, set before
    # anything is uploaded, but both the word and the value read as
    # "the upload finished fine". Labelled as an intention now, so it
    # cannot be mistaken for an outcome even when it is the last line
    # left on screen.
    print("About to upload:")
    print(f"  Package:       {args.package_name}")
    print(f"  AAB:           {args.aab}")
    print(f"  Tracks:        {', '.join(tracks)}")
    print(f"  Release state: {args.status} (once uploaded)")
    if not args.yes:
        reply = input("Proceed with this upload? [y/N] ").strip().lower()
        if reply != "y":
            print("Aborted.")
            return 1

    try:
        edit = edits.insert(packageName=args.package_name, body={}).execute()
        edit_id = edit["id"]

        # Explicit mimetype: Python's mimetypes module has no entry
        # for .aab, and media_body=<path string> lets googleapiclient
        # guess from the extension and fail with UnknownFileType.
        media = MediaFileUpload(
            str(args.aab), mimetype="application/octet-stream"
        )
        upload = (
            edits.bundles()
            .upload(
                packageName=args.package_name,
                editId=edit_id,
                media_body=media,
            )
            .execute()
        )
        version_code = upload["versionCode"]
        print(f"Uploaded: versionCode {version_code}")

        release: dict = {
            "versionCodes": [str(version_code)],
            "status": args.status,
        }
        if args.release_notes:
            release["releaseNotes"] = [
                {
                    "language": args.release_notes_language,
                    "text": args.release_notes,
                }
            ]

        # One edit, several tracks: the bundle is uploaded once and
        # each track points at the same versionCode.
        for track in tracks:
            edits.tracks().update(
                packageName=args.package_name,
                editId=edit_id,
                track=track,
                body={"releases": [release]},
            ).execute()

        # Play's API has flip-flopped on changesNotSentForReview: it
        # used to reject a bare commit ("must set the query parameter
        # ... to true"), and has been seen (on sanlo) to reject a
        # commit that SETS it ("must not be set"). Rather than guess
        # which behaviour is current, try with the parameter first
        # (the documented, safer default -- it is what stops an
        # internal-testing push from accidentally kicking off policy
        # review) and fall back to a bare commit only if Play
        # specifically complains that it must not be set.
        try:
            edits.commit(
                packageName=args.package_name,
                editId=edit_id,
                changesNotSentForReview=not args.send_for_review,
            ).execute()
        except HttpError as commit_error:
            if "must not be set" not in str(commit_error):
                raise
            print(
                "note: Play rejected changesNotSentForReview for this "
                "edit; retrying a bare commit.",
                file=sys.stderr,
            )
            edits.commit(
                packageName=args.package_name, editId=edit_id
            ).execute()
    except HttpError as e:
        print(f"error: Play API call failed: {e}", file=sys.stderr)
        print(
            "  Common causes: the service account lacks access to "
            "this app in Play Console (Users and permissions), or the "
            "Android Publisher API isn't enabled on the linked "
            "Google Cloud project.",
            file=sys.stderr,
        )
        return 1

    print(
        f"Done. versionCode {version_code} is now on the "
        f"{', '.join(repr(track) for track in tracks)} "
        f"track(s) ({args.status}). Check Play Console -> "
        f"{args.package_name} -> Testing to confirm and see the "
        "testers' opt-in links."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
