#!/usr/bin/env python3
"""AI-assisted PR review.

Reads a unified diff (from stdin or a file passed as argv[1]) and asks an
OpenAI-compatible chat endpoint to review it for security, IaC, and best
practices. Prints the review to stdout; if AZURE DevOps PR variables are
present it also posts the review as a PR thread comment.

Design notes:
  * Fails OPEN (exit 0) so it can run as a non-blocking advisory gate.
  * No API keys are stored in the repo; they come from env vars.
  * Skips cleanly when OPENAI_API_KEY is unset (e.g. forks / local runs).

Env vars:
  OPENAI_API_KEY   required to actually call the model (otherwise skips)
  OPENAI_API_URL   default https://api.openai.com/v1/chat/completions
  OPENAI_MODEL     default gpt-4o-mini
  SYSTEM_ACCESSTOKEN + BUILD_REPOSITORY_ID + SYSTEM_PULLREQUEST_PULLREQUESTID
                   optional: when set, posts the review back to the ADO PR
  SYSTEM_TEAMFOUNDATIONCOLLECTIONURI + SYSTEM_TEAMPROJECT  (ADO, optional)
"""
import json
import os
import sys
import urllib.request


def read_diff() -> str:
    if len(sys.argv) > 1 and sys.argv[1] not in ("-", ""):
        with open(sys.argv[1], "r", encoding="utf-8", errors="replace") as fh:
            return fh.read()
    if not sys.stdin.isatty():
        return sys.stdin.read()
    return ""


def call_openai(diff_text: str) -> str | None:
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("OPENAI_API_KEY not set; skipping AI review (non-blocking).")
        return None
    url = os.environ.get("OPENAI_API_URL", "https://api.openai.com/v1/chat/completions")
    model = os.environ.get("OPENAI_MODEL", "gpt-4o-mini")
    # Keep the prompt bounded so we don't blow the context window on huge diffs.
    diff_text = diff_text[:60000]
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": "You are a senior DevOps/security reviewer. "
             "Return concise, actionable bullets covering security, IaC misconfigurations, "
             "secrets handling, and CI/CD risks. If nothing is wrong, say so briefly."},
            {"role": "user", "content": f"Review this PR diff:\n\n{diff_text}"},
        ],
        "max_tokens": 600,
        "temperature": 0.1,
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            body = json.loads(resp.read().decode("utf-8"))
        return body["choices"][0]["message"]["content"]
    except Exception as exc:  # noqa: BLE001 - advisory tool, never break the build
        print(f"AI call failed (non-blocking): {exc}")
        return None


def post_to_ado(review: str) -> None:
    token = os.environ.get("SYSTEM_ACCESSTOKEN")
    pr_id = os.environ.get("SYSTEM_PULLREQUEST_PULLREQUESTID")
    repo_id = os.environ.get("BUILD_REPOSITORY_ID")
    org_url = os.environ.get("SYSTEM_TEAMFOUNDATIONCOLLECTIONURI")
    project = os.environ.get("SYSTEM_TEAMPROJECT")
    if not all([token, pr_id, repo_id, org_url, project]):
        return
    url = (f"{org_url}{project}/_apis/git/repositories/{repo_id}/pullRequests/"
           f"{pr_id}/threads?api-version=7.1")
    body = {"comments": [{"parentCommentId": 0, "commentType": 1,
                          "content": f"### AI review\n\n{review}"}], "status": 1}
    req = urllib.request.Request(
        url, data=json.dumps(body).encode("utf-8"),
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="POST",
    )
    try:
        urllib.request.urlopen(req, timeout=30)
        print("Posted AI review to the ADO pull request.")
    except Exception as exc:  # noqa: BLE001
        print(f"Could not post PR comment (non-blocking): {exc}")


def main() -> int:
    diff = read_diff().strip()
    if not diff:
        print("No diff provided; nothing to review.")
        return 0
    review = call_openai(diff)
    if review:
        print("\n===== AI PR REVIEW =====\n")
        print(review)
        post_to_ado(review)
    return 0


if __name__ == "__main__":
    sys.exit(main())
