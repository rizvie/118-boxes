#!/usr/bin/env python3
"""Idempotently set up the internal TestFlight group for 118 Boxes.

Run once after the App Store Connect app record exists. Safe to re-run.

A build being VALID and READY_FOR_BETA_TESTING is not enough to install it. It
also has to be distributable to a group, and a brand new app record has none, so
TestFlight on the phone shows nothing at all.

The tester's details come from the environment, never from this file, because
this repository is public:

    TESTFLIGHT_TESTER_EMAIL   required
    TESTFLIGHT_TESTER_FIRST   optional
    TESTFLIGHT_TESTER_LAST    optional

Three App Store Connect API quirks are baked in here, all found the hard way on
an earlier app:

1. `hasAccessToAllBuilds` can only be set when the group is CREATED. PATCHing it
   later returns 409 ENTITY_ERROR.ATTRIBUTE.NOT_ALLOWED. Get it right up front,
   or delete and recreate the group.

2. When a group has `hasAccessToAllBuilds=True`, you must NOT assign builds to
   it. Every build is available automatically, and POSTing to the builds
   relationship returns 422 "Builds cannot be assigned to this internal group."

3. Adding an existing tester via POST /v1/betaGroups/{id}/relationships/betaTesters
   returns 409 STATE_ERROR "Tester(s) cannot be assigned". Creating the tester
   with the betaGroups relationship inline on POST /v1/betaTesters works instead.
"""
import json, os, sys, time, urllib.error, urllib.request

import jwt

APP_ID = "6809168683"          # 118 Boxes: Periodic Table

EMAIL = os.environ.get("TESTFLIGHT_TESTER_EMAIL", "").strip()
FIRST = os.environ.get("TESTFLIGHT_TESTER_FIRST", "Internal").strip()
LAST = os.environ.get("TESTFLIGHT_TESTER_LAST", "Tester").strip()
if not EMAIL:
    sys.exit("Set TESTFLIGHT_TESTER_EMAIL to the Apple ID that should test builds.")
GROUP_NAME = os.environ.get("TESTFLIGHT_GROUP_NAME", "Internal")


def token() -> str:
    env = {}
    path = os.environ.get("BOXES118_ASC_ENV", os.path.expanduser("~/.clipper-asc.env"))
    for line in open(path):
        line = line.strip()
        if line and "=" in line and not line.startswith("#"):
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip().strip('"').strip("'")
    kid, iss = env["ASC_KEY_ID"], env["ASC_ISSUER_ID"]
    key = open(os.path.expanduser(
        f"~/.appstoreconnect/private_keys/AuthKey_{kid}.p8")).read()
    return jwt.encode(
        {"iss": iss, "exp": int(time.time()) + 900, "aud": "appstoreconnect-v1"},
        key, algorithm="ES256", headers={"kid": kid, "typ": "JWT"})


TOK = token()
HDR = {"Authorization": f"Bearer {TOK}", "Content-Type": "application/json"}


def call(path, data=None, method=None):
    req = urllib.request.Request(
        "https://api.appstoreconnect.apple.com" + path,
        data=json.dumps(data).encode() if data else None,
        headers=HDR, method=method or ("POST" if data else "GET"))
    try:
        body = urllib.request.urlopen(req).read()
        return json.loads(body) if body else {"ok": True}
    except urllib.error.HTTPError as e:
        return {"err": e.code, "body": e.read().decode()[:300]}


def main() -> int:
    groups = call(f"/v1/betaGroups?filter[app]={APP_ID}").get("data", [])
    group = next((g for g in groups if g["attributes"]["isInternalGroup"]), None)

    if group and not group["attributes"].get("hasAccessToAllBuilds"):
        print("Internal group exists but lacks all-builds access; recreating.")
        call(f"/v1/betaGroups/{group['id']}", None, "DELETE")
        group = None

    if not group:
        res = call("/v1/betaGroups", {"data": {
            "type": "betaGroups",
            "attributes": {"name": GROUP_NAME, "isInternalGroup": True,
                           "hasAccessToAllBuilds": True},   # quirk 1
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}}}})
        if "err" in res:
            print("Could not create the group:", res, file=sys.stderr)
            return 1
        group = res["data"]
        print(f"Created internal group {GROUP_NAME!r}.")
    else:
        print(f"Internal group {group['attributes']['name']!r} already set up.")

    gid = group["id"]
    # No build assignment here: quirk 2.

    current = [t["attributes"]["email"]
               for t in call(f"/v1/betaGroups/{gid}/betaTesters").get("data", [])]
    if EMAIL in current:
        print("Tester is already in the group.")
    else:
        res = call("/v1/betaTesters", {"data": {                # quirk 3
            "type": "betaTesters",
            "attributes": {"email": EMAIL, "firstName": FIRST, "lastName": LAST},
            "relationships": {"betaGroups": {
                "data": [{"type": "betaGroups", "id": gid}]}}}})
        if "err" in res:
            print("Could not add the tester:", res, file=sys.stderr)
            return 1
        print("Added the tester to the internal group.")

    builds = call(f"/v1/builds?filter[app]={APP_ID}&limit=3&sort=-uploadedDate")
    print("\nBuilds:")
    for b in builds.get("data", []):
        a = b["attributes"]
        exp = (a.get("expirationDate") or "")[:10]
        print(f"  v{a['version']}  {a['processingState']}  expires {exp}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
