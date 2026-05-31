"""
ADO Monitoring Dashboard — Azure Functions v2 (Python 3.11)

Routes (routePrefix = ""):
  POST /events          Receive a pipeline run event from ADO (x-api-key auth)
  GET  /events          Return the last 100 events as JSON (Entra ID auth)
  GET  /                Serve the dashboard SPA (Entra ID auth, redirect to login if not)
  GET  /{*path}         Catch-all → redirects to / (keeps the SPA clean)

No external dependencies beyond azure-functions (stdlib only for Table Storage).
"""

import base64
import datetime
import hashlib
import hmac
import json
import logging
import os
import urllib.error
import urllib.parse
import urllib.request
from datetime import timezone

import azure.functions as func

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# ── Constants ────────────────────────────────────────────────────────────────

_TABLE_NAME = os.environ.get("TABLE_NAME", "pipelineevents")
_CONN_STR_ENV = "TABLE_STORAGE_CONNECTION_STRING"
_API_KEY_ENV = "INGEST_API_KEY"

_REQUIRED_FIELDS = [
    "pipelineName",
    "buildId",
    "buildNumber",
    "status",
    "branch",
    "projectName",
    "startTime",
    "finishTime",
]

# ── Azure Table Storage (stdlib only — no external packages) ─────────────────


def _parse_conn_str(conn_str):
    """Return (account_name, account_key) from an Azure storage connection string."""
    parts = dict(item.split("=", 1) for item in conn_str.split(";") if "=" in item)
    return parts["AccountName"], parts["AccountKey"]


def _table_sign(account_key, string_to_sign):
    key = base64.b64decode(account_key)
    sig = hmac.new(key, string_to_sign.encode("utf-8"), digestmod=hashlib.sha256).digest()
    return base64.b64encode(sig).decode()


def _table_headers(account_name, account_key, resource, body=b""):
    """SharedKeyLite auth headers for Azure Table Storage."""
    date = datetime.datetime.now(timezone.utc).strftime("%a, %d %b %Y %H:%M:%S GMT")
    string_to_sign = "{}\n/{}/{}".format(date, account_name, resource)
    auth = "SharedKeyLite {}:{}".format(
        account_name, _table_sign(account_key, string_to_sign)
    )
    headers = {
        "Authorization": auth,
        "x-ms-date": date,
        "x-ms-version": "2020-12-06",
        "Accept": "application/json;odata=nometadata",
        "DataServiceVersion": "3.0",
    }
    if body:
        headers["Content-Type"] = "application/json"
        headers["Content-Length"] = str(len(body))
    return headers


def _table_base(account_name):
    return "https://{}.table.core.windows.net".format(account_name)


def _ensure_table():
    conn_str = os.environ[_CONN_STR_ENV]
    account_name, account_key = _parse_conn_str(conn_str)
    body = json.dumps({"TableName": _TABLE_NAME}).encode("utf-8")
    url = "{}/Tables".format(_table_base(account_name))
    headers = _table_headers(account_name, account_key, "Tables", body)
    req = urllib.request.Request(url, data=body, headers=headers, method="POST")
    try:
        urllib.request.urlopen(req).close()
    except urllib.error.HTTPError as exc:
        if exc.code != 409:  # 409 = TableAlreadyExists — safe to ignore
            raise


def _upsert_entity(entity):
    conn_str = os.environ[_CONN_STR_ENV]
    account_name, account_key = _parse_conn_str(conn_str)
    pk = entity["PartitionKey"]
    rk = entity["RowKey"]
    resource = "{}(PartitionKey='{}',RowKey='{}')".format(_TABLE_NAME, pk, rk)
    url_path = "{}(PartitionKey='{}',RowKey='{}')".format(
        _TABLE_NAME,
        urllib.parse.quote(pk, safe=""),
        urllib.parse.quote(rk, safe=""),
    )
    body = json.dumps(entity).encode("utf-8")
    headers = _table_headers(account_name, account_key, resource, body)
    req = urllib.request.Request(
        "{}/{}".format(_table_base(account_name), url_path),
        data=body, headers=headers, method="PUT",
    )
    urllib.request.urlopen(req).close()


def _list_entities():
    conn_str = os.environ[_CONN_STR_ENV]
    account_name, account_key = _parse_conn_str(conn_str)
    base_url = "{}/{}".format(_table_base(account_name), _TABLE_NAME)
    results = []
    next_url = base_url
    while next_url:
        headers = _table_headers(account_name, account_key, _TABLE_NAME)
        req = urllib.request.Request(next_url, headers=headers, method="GET")
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read())
            results.extend(data.get("value", []))
            cont_pk = resp.headers.get("x-ms-continuation-NextPartitionKey")
            cont_rk = resp.headers.get("x-ms-continuation-NextRowKey")
            if cont_pk:
                params = {"NextPartitionKey": cont_pk}
                if cont_rk:
                    params["NextRowKey"] = cont_rk
                next_url = "{}?{}".format(base_url, urllib.parse.urlencode(params))
            else:
                next_url = None
    return results


# ── Helpers ───────────────────────────────────────────────────────────────────


def _safe_json_loads(value):
    try:
        return json.loads(value) if value else []
    except Exception:
        return []


def _valid_api_key(req: func.HttpRequest) -> bool:
    expected = os.environ.get(_API_KEY_ENV, "")
    if not expected:
        logging.warning("INGEST_API_KEY app setting is empty — ingest is disabled")
        return False
    provided = req.headers.get("x-api-key", "")
    # Constant-time comparison prevents timing-based key enumeration
    return hmac.compare_digest(expected.encode(), provided.encode())


def _authenticated(req: func.HttpRequest) -> bool:
    """Return True when Easy Auth has injected a valid Entra ID principal."""
    return bool(req.headers.get("x-ms-client-principal", ""))


def _principal_name(req: func.HttpRequest) -> str:
    raw = req.headers.get("x-ms-client-principal", "")
    if not raw:
        return "Unknown"
    try:
        data = json.loads(base64.b64decode(raw + "=="))
        claims = {c["typ"]: c["val"] for c in data.get("claims", [])}
        return (
            claims.get("preferred_username")
            or claims.get("name")
            or claims.get("upn")
            or "Unknown"
        )
    except Exception:
        return "Unknown"


def _login_redirect(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse(
        status_code=302,
        headers={"Location": "/.auth/login/aad?post_login_redirect_uri=/"},
    )


# ── POST /events — ingest pipeline run ───────────────────────────────────────


@app.route(route="events", methods=["POST"])
def ingest_event(req: func.HttpRequest) -> func.HttpResponse:
    if not _valid_api_key(req):
        return func.HttpResponse("Unauthorized", status_code=401)

    try:
        body: dict = req.get_json()
    except ValueError:
        return func.HttpResponse("Bad Request: body must be valid JSON", status_code=400)

    missing = [f for f in _REQUIRED_FIELDS if f not in body]
    if missing:
        return func.HttpResponse(
            f"Bad Request: missing required fields: {missing}", status_code=400
        )

    now = datetime.datetime.now(timezone.utc)
    entity = {
        "PartitionKey": now.strftime("%Y-%m"),
        "RowKey": str(body["buildId"]),
        "PipelineName": str(body.get("pipelineName", "")),
        "BuildNumber": str(body.get("buildNumber", "")),
        "Status": str(body.get("status", "")),
        "Branch": str(body.get("branch", "")),
        "TriggeredBy": str(body.get("triggeredBy", "")),
        "ProjectName": str(body.get("projectName", "")),
        "RepositoryName": str(body.get("repositoryName", "")),
        "Environment": str(body.get("environment", "")),
        "StartTime": str(body.get("startTime", "")),
        "FinishTime": str(body.get("finishTime", "")),
        "DurationSeconds": int(body.get("durationSeconds", 0)),
        "ReceivedAt": now.isoformat(),
        # ── Enrichment fields (all optional) ────────────────────────────
        "ServiceName": str(body.get("serviceName", "")),
        "ReleaseVersion": str(body.get("releaseVersion", "")),
        "CommitId": str(body.get("commitId", "")),
        "CommitTimestamp": str(body.get("commitTimestamp", "")),
        "PullRequestId": str(body.get("pullRequestId", "")),
        "IsRollback": bool(body.get("isRollback", False)),
        "FailureReason": str(body.get("failureReason", "")),
        "FailedStage": str(body.get("failedStage", "")),
        # Work item IDs stored as a JSON array string (Table Storage has no array type)
        "WorkItemIds": json.dumps(body.get("workItemIds", [])),
        "TestsPassed": int(body.get("testsPassed", 0)),
        "TestsFailed": int(body.get("testsFailed", 0)),
    }

    _ensure_table()
    _upsert_entity(entity)
    logging.info(
        "Stored event for build %s — %s/%s",
        body["buildId"],
        body.get("projectName"),
        body.get("pipelineName"),
    )
    return func.HttpResponse("", status_code=204)


# ── GET /events — dashboard data API ─────────────────────────────────────────


@app.route(route="events", methods=["GET"])
def get_events(req: func.HttpRequest) -> func.HttpResponse:
    if not _authenticated(req):
        return func.HttpResponse(
            json.dumps({"error": "Unauthorized"}),
            status_code=401,
            mimetype="application/json",
        )

    try:
        entities = _list_entities()
    except Exception:
        logging.exception("Failed to query Table Storage")
        return func.HttpResponse(
            json.dumps({"error": "Failed to retrieve events"}),
            status_code=500,
            mimetype="application/json",
        )

    entities.sort(key=lambda e: e.get("ReceivedAt", ""), reverse=True)

    events = [
        {
            "pipelineName": e.get("PipelineName", ""),
            "buildNumber": e.get("BuildNumber", ""),
            "status": e.get("Status", ""),
            "branch": e.get("Branch", ""),
            "triggeredBy": e.get("TriggeredBy", ""),
            "projectName": e.get("ProjectName", ""),
            "repositoryName": e.get("RepositoryName", ""),
            "environment": e.get("Environment", ""),
            "startTime": e.get("StartTime", ""),
            "finishTime": e.get("FinishTime", ""),
            "durationSeconds": int(e.get("DurationSeconds", 0)),
            "receivedAt": e.get("ReceivedAt", ""),
            # ── Enrichment fields ────────────────────────────────────────
            "serviceName": e.get("ServiceName", ""),
            "releaseVersion": e.get("ReleaseVersion", ""),
            "commitId": e.get("CommitId", ""),
            "commitTimestamp": e.get("CommitTimestamp", ""),
            "pullRequestId": e.get("PullRequestId", ""),
            "isRollback": bool(e.get("IsRollback", False)),
            "failureReason": e.get("FailureReason", ""),
            "failedStage": e.get("FailedStage", ""),
            "workItemIds": _safe_json_loads(e.get("WorkItemIds", "[]")),
            "testsPassed": int(e.get("TestsPassed", 0)),
            "testsFailed": int(e.get("TestsFailed", 0)),
        }
        for e in entities[:100]
    ]

    return func.HttpResponse(json.dumps(events), mimetype="application/json")


# ── GET / and GET /{*path} — serve dashboard SPA ─────────────────────────────


def _serve_html(req: func.HttpRequest) -> func.HttpResponse:
    if not _authenticated(req):
        return _login_redirect(req)

    html_path = os.path.join(os.path.dirname(__file__), "static", "index.html")
    try:
        with open(html_path, encoding="utf-8") as fh:
            html = fh.read()
    except FileNotFoundError:
        return func.HttpResponse("Dashboard not found", status_code=404)

    return func.HttpResponse(html, mimetype="text/html")


@app.route(route="", methods=["GET"])
def serve_root(req: func.HttpRequest) -> func.HttpResponse:
    return _serve_html(req)


@app.route(route="{*path}", methods=["GET"])
def serve_dashboard(req: func.HttpRequest) -> func.HttpResponse:
    return _serve_html(req)
