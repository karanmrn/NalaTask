"""Generate deterministic synthetic RAW landing tables for local DuckDB development.

Writes CSV seeds under seeds/raw/. Row shapes follow docs/assessment_brief.md exactly,
plus connector metadata columns:
  StreamServe tables : _cdc_operation, _cdc_lsn, _cdc_loaded_at  (append-only change log)
  Fivetran table     : _fivetran_synced
Data is fake. Volumes are tiny. Edge cases are seeded on purpose (see EDGE CASES below).
Run: uv run python scripts/generate_synthetic_raw.py
"""
from __future__ import annotations

import csv
import json
import random
import uuid
from datetime import datetime, timedelta, date
from pathlib import Path

random.seed(42)
ROOT = Path(__file__).resolve().parents[1] / "seeds" / "raw"
AS_OF = datetime(2026, 9, 7, 12, 0, 0)
START = AS_OF - timedelta(days=45)
LSN = 1000


def uid() -> str:
    return str(uuid.UUID(int=random.getrandbits(128)))


def ts(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def rand_ts(start: datetime = START, end: datetime = AS_OF) -> datetime:
    return start + timedelta(seconds=random.randint(0, int((end - start).total_seconds())))


def cdc(rows: list[dict], op: str = "INSERT") -> list[dict]:
    global LSN
    out = []
    for r in rows:
        LSN += 1
        out.append({**r, "_cdc_operation": op, "_cdc_lsn": LSN, "_cdc_loaded_at": ts(AS_OF - timedelta(minutes=random.randint(1, 30)))})
    return out


def write(schema: str, name: str, rows: list[dict]) -> None:
    path = ROOT / schema / f"{name}.csv"
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print(f"{schema}.{name}: {len(rows)} rows")


# ----------------------------------------------------------------------------- payments
COUNTRIES = {"GB": "GBP", "US": "USD", "DE": "EUR"}
DEST = {"KES": ("KE", "MPESA"), "TZS": ("TZ", "AIRTEL"), "NGN": ("NG", None), "UGX": ("UG", "MTN")}
PROVIDERS = ["THUNES", "TERRAPAY", "CELLULANT"]

users, accounts = [], []
for _ in range(60):
    c = random.choice(list(COUNTRIES))
    created = rand_ts(START - timedelta(days=200), AS_OF - timedelta(days=1))
    approved = created + timedelta(hours=random.randint(1, 72)) if random.random() < 0.9 else None
    u = {
        "id": uid(), "status": random.choices(["ACTIVE", "INACTIVE", "SUSPENDED", "PENDING"], [80, 10, 5, 5])[0],
        "source": json.dumps({"link": f"https://nala.app/r/{random.randint(1000, 9999)}"}),
        "sender_country": c, "created": ts(created), "allowed": ts(approved) if approved else "",
        "client_properties": json.dumps({"os": random.choice(["iOS", "Android"])}),
        "used_invitation_code_id": uid() if random.random() < 0.3 else "", "profile_picture": "",
        "usage": json.dumps({"sender_country": c, "recipient_countries": random.sample(["KE", "TZ", "NG", "UG"], 2)}),
    }
    users.append(u)
    accounts.append({
        "id": uid(), "owner_id": u["id"], "name": "Personal", "type": "PERSONAL", "status": "ACTIVE",
        "features": json.dumps({"cards": True}), "created": u["created"], "last_updated": u["created"],
        "profile_id": uid(), "limit_level": random.choice(["L1", "L2", "L3"]),
        "client_properties": "{}", "deleted": "",
    })

recipients, recipient_accounts = [], []
for a in accounts:
    for _ in range(random.randint(1, 2)):
        cur = random.choice(list(DEST))
        country, operator = DEST[cur]
        r = {"id": uid(), "account_id": a["id"], "first_name": "Test", "last_name": "Recipient",
             "type": "INDIVIDUAL", "created_at": a["created"], "updated_at": a["created"]}
        recipients.append(r)
        recipient_accounts.append({
            "id": uid(), "recipient_id": r["id"], "type": "MOBILE_MONEY" if operator else "BANK_ACCOUNT",
            "country": country, "currency": cur, "phone_number": "+2547000000" if operator else "",
            "operator": operator or "", "account_number": "" if operator else "0011223344",
            "bank_code": "" if operator else "058", "bank_name": "" if operator else "GTBank",
            "created_at": r["created_at"], "updated_at": r["created_at"],
        })

TX_TYPES = ["COLLECTION_CONVERSION_DISBURSEMENT"] * 60 + ["CONVERSION_DISBURSEMENT"] * 10 + ["DISBURSEMENT"] * 5 \
    + ["OUTGOING_PEER_TO_PEER"] * 5 + ["INCOMING_PEER_TO_PEER"] * 5 + ["COLLECTION"] * 5 + ["EARNED_REWARD"] * 3 \
    + ["REVERSAL"] * 2 + ["CONVERSION"] * 2 + ["INCOMING_COLLECTION"] * 3
STATES = ["COMPLETED"] * 70 + ["FAILED"] * 10 + ["CANCELLED"] * 5 + ["EXPIRED"] * 5 + ["DISBURSEMENT_IN_PROGRESS"] * 5 + ["ON_HOLD"] * 5

transactions, collections, disbursements, attempts = [], [], [], []
ra_by_account = {}
for ra in recipient_accounts:
    rec = next(r for r in recipients if r["id"] == ra["recipient_id"])
    ra_by_account.setdefault(rec["account_id"], []).append((rec, ra))

for i in range(400):
    a = random.choice(accounts)
    u = next(x for x in users if x["id"] == a["owner_id"])
    rec, ra = random.choice(ra_by_account[a["id"]])
    tx_type = random.choice(TX_TYPES)
    state = random.choice(STATES)
    created = rand_ts()
    updated = created + timedelta(minutes=random.randint(1, 3000))
    sent_cur = COUNTRIES[u["sender_country"]]
    sent = round(random.uniform(20, 900), 2)
    rate = {"KES": 165.0, "TZS": 3300.0, "NGN": 1900.0, "UGX": 4800.0}[ra["currency"]] * (1.3 if sent_cur == "GBP" else 1.1 if sent_cur == "EUR" else 1.0)
    has_disb = "DISBURSEMENT" in tx_type
    has_coll = "COLLECTION" in tx_type
    t = {
        "id": uid(), "user_id": u["id"], "account_id": a["id"], "type": tx_type, "state": state,
        "sent_amount": sent, "sent_currency": sent_cur, "received_amount": round(sent * rate, 2),
        "received_currency": ra["currency"], "exchange_rate": round(rate, 6), "source_amount": round(sent + 2.5, 2),
        "recipient_id": rec["id"] if has_disb else "", "recipient_account_id": ra["id"] if has_disb else "",
        "workflow_id": "", "created_at": ts(created), "updated_at": ts(updated), "expires_at": ts(created + timedelta(hours=24)),
        "memo": "", "purpose": random.choice(["REMITTANCE", "BILLS_PAYMENT", "GOODS_PURCHASE"]),
        "from_wallet_id": "", "to_wallet_id": "",
        "summary": json.dumps({"original": {"source_amount": {"amount": sent + 2.5}}, "fees": [{"definition": {"label": "Transfer fee", "kind": "FIXED"}}]}),
        "metadata": "{}", "fee_label": "Transfer fee", "fee_kind": "FIXED",
    }
    transactions.append(t)
    if has_coll:
        collections.append({"id": uid(), "transaction_id": t["id"], "account_id": a["id"],
                            "state": "COMPLETED" if state != "FAILED" else "FAILED", "amount": sent, "currency": sent_cur,
                            "to_wallet_id": uid(), "created_at": t["created_at"], "updated_at": t["updated_at"]})
    if has_disb:
        d_state = {"COMPLETED": "COMPLETED", "FAILED": "FAILED"}.get(state, "WAITING_ON_PROVIDER")
        d = {"id": uid(), "transaction_id": t["id"], "state": d_state, "amount": t["received_amount"],
             "currency": ra["currency"], "recipient_id": rec["id"], "recipient_account_id": ra["id"],
             "provider_name": random.choice(PROVIDERS), "created_at": t["created_at"], "updated_at": t["updated_at"]}
        disbursements.append(d)
        n_attempts = 1 if random.random() < 0.8 else 2
        attempt_created = created + timedelta(seconds=30)
        for k in range(n_attempts):
            last = k == n_attempts - 1
            a_state = d_state if last else "FAILED"
            provider = d["provider_name"] if last else random.choice([p for p in PROVIDERS if p != d["provider_name"]])
            # EDGE CASE: latency spread across all six bands, including exactly 24h.
            secs = random.choice([15, 45, 90, 240, 600, 1500, 2400, 3599, 3600, 40000, 86400, 86401, 100000, 300000])
            a_updated = attempt_created + timedelta(seconds=secs) if a_state in ("COMPLETED", "FAILED") else attempt_created + timedelta(minutes=5)
            attempts.append({
                "id": uid(), "disbursement_id": d["id"], "state": a_state, "provider_name": provider,
                "provider_id": f"P{random.randint(100000, 999999)}", "selection_reason": random.choice(["PRIORITY_ORDER", "SMART_ROUTING", "PREDEFINED", "PROBING"]),
                "provider_error_category": "" if a_state == "COMPLETED" else random.choice(["INSUFFICIENT_FUNDS", "INVALID_ACCOUNT", "PROVIDER_TIMEOUT"]),
                "created_at": ts(attempt_created), "last_updated_at": ts(a_updated),
                "eta": ts(attempt_created + timedelta(minutes=10)), "max_eta": ts(attempt_created + timedelta(hours=24)),
                "error": "" if a_state == "COMPLETED" else "provider declined", "provider_error": "" if a_state == "COMPLETED" else "ERR_42",
                "receipt_number": f"R{random.randint(10**6, 10**7)}" if a_state == "COMPLETED" else "", "psp_account_id": uid(),
            })
            attempt_created = a_updated + timedelta(seconds=10)

# EDGE CASE: CDC change log. One transaction moves IN_PROGRESS -> COMPLETED (two log rows),
# one transaction is hard-deleted, one user changes status.
tx_log = cdc(transactions)
progressing = transactions[0]
old_row = {**progressing, "state": "DISBURSEMENT_IN_PROGRESS", "updated_at": progressing["created_at"]}
tx_log = cdc([old_row]) + tx_log  # older LSN first; latest row must win
deleted_tx = transactions[1]
tx_log += cdc([deleted_tx], "DELETE")
deleted_children = {"collections": [c for c in collections if c["transaction_id"] == deleted_tx["id"]],
                    "disbursements": [d for d in disbursements if d["transaction_id"] == deleted_tx["id"]]}
deleted_children["attempts"] = [a for a in attempts if a["disbursement_id"] in {d["id"] for d in deleted_children["disbursements"]}]
user_log = cdc(users) + cdc([{**users[0], "status": "SUSPENDED"}], "UPDATE")

# ----------------------------------------------------------------------------- fincrime
rules = []
rule_defs = [("high_value_transaction_check", "THRESHOLD", "AML"), ("velocity_check", "PATTERN", "FRAUD"),
             ("sanctions_list_check", "LIST_CHECK", "SANCTIONS"), ("new_recipient_large_amount", "PATTERN", "FRAUD"),
             ("high_risk_country", "LIST_CHECK", "AML")]
for name, rtype, cat in rule_defs:
    for v in (1, 2):
        rules.append({"id": uid(), "name": name, "title": name.replace("_", " ").title(), "description": f"Checks {name}",
                      "type": rtype, "category": cat, "team": "fincrime", "condition": "amount > 500", "version": v,
                      "created_at": ts(START - timedelta(days=100 - v * 10)), "updated_at": ts(START - timedelta(days=100 - v * 10)),
                      "deleted_at": ts(START - timedelta(days=80)) if v == 1 else ""})  # EDGE CASE: v1 soft-deleted, still referenced
current_rules = [r for r in rules if r["version"] == 2]

workflows = []
for wtype, wname in [("PRE_TRANSACTION", "pre_transaction_screening"), ("USER_ONBOARDING", "onboarding_screening")]:
    workflows.append({"id": uid(), "name": wname, "title": wname.replace("_", " ").title(), "type": wtype,
                      "config": json.dumps({"nodes": [{"type": "RULE", "config": {"rule_id": r["id"]}} for r in current_rules[:3]]}),
                      "version": 1, "created_at": ts(START - timedelta(days=90)), "updated_at": ts(START - timedelta(days=90)), "deleted_at": ""})

workflow_executions, rule_executions, reviews, tasks = [], [], [], []
task_source_tx = random.sample(transactions, 60)
for t in task_source_tx:
    u = next(x for x in users if x["id"] == t["user_id"])
    created = datetime.strptime(t["created_at"], "%Y-%m-%d %H:%M:%S") + timedelta(seconds=5)
    fail = random.random() < 0.35
    actions = ["HOLD_TRANSACTION", "CREATE_TASK"] if fail else []
    we = {"id": uid(), "workflow_id": workflows[0]["id"], "result": "FAIL" if fail else "PASS",
          "context": json.dumps({"user_id": u["id"], "transaction_id": t["id"]}),
          "created_at": ts(created), "started_at": ts(created), "ended_at": ts(created + timedelta(seconds=2)),
          "error": "", "actions": json.dumps(actions)}
    workflow_executions.append(we)
    for r in random.sample(rules, 3):
        r_fail = fail and random.random() < 0.6
        re_ = {"id": uid(), "rule_id": r["id"], "workflow_execution_id": we["id"], "result": "FAIL" if r_fail else "PASS",
               "condition_result": str(r_fail).lower(), "context": we["context"], "created_at": we["created_at"],
               "started_at": we["started_at"], "ended_at": we["ended_at"], "error": "",
               "review": "REVIEWED" if r_fail else "", "review_comment": "", "reviewer_id": uid() if r_fail else "",
               "reviewed_at": ts(created + timedelta(hours=random.randint(1, 48))) if r_fail else ""}
        rule_executions.append(re_)
        if r_fail:
            n_reviews = 2 if random.random() < 0.15 else 1  # EDGE CASE: repeat formal reviews on one execution
            for _ in range(n_reviews):
                reviews.append({"id": uid(), "rule_execution_id": re_["id"], "reviewer_id": uid(),
                                "review": random.choices(["FALSE_POSITIVE", "TRUE_POSITIVE", "INCONCLUSIVE"], [55, 30, 15])[0],
                                "review_comment": "reviewed", "reviewed_at": ts(created + timedelta(hours=random.randint(1, 72)))})
    if fail:
        task_created = created + timedelta(minutes=random.randint(1, 50))
        resolved = random.random() < 0.7
        tasks.append({"id": uid(), "service": "fincrime", "type": "transaction_review",
                      "state": "RESOLVED" if resolved else random.choice(["OPEN", "IN_PROGRESS"]),
                      "priority": random.choice(["LOW", "MEDIUM", "HIGH", "CRITICAL"]), "staff_id": "", "assignee_id": uid(),
                      "associated_ids": json.dumps([t["id"], t["account_id"], u["id"]]),
                      "content": json.dumps({"account_id": t["account_id"]}),
                      "created_at": ts(task_created), "last_updated_at": ts(task_created + timedelta(hours=random.randint(1, 96))) if resolved else ts(task_created),
                      "resolution": random.choice(["APPROVED", "REJECTED", "ESCALATED"]) if resolved else ""})
# EDGE CASE: user-level onboarding workflows, one producing a user_review task, plus a support task (not fincrime).
for u in random.sample(users, 8):
    created = datetime.strptime(u["created"], "%Y-%m-%d %H:%M:%S") + timedelta(minutes=1)
    fail = random.random() < 0.5
    we = {"id": uid(), "workflow_id": workflows[1]["id"], "result": "FAIL" if fail else "PASS",
          "context": json.dumps({"user_id": u["id"]}), "created_at": ts(created), "started_at": ts(created),
          "ended_at": ts(created + timedelta(seconds=1)), "error": "", "actions": json.dumps(["BLOCK_USER", "CREATE_TASK"] if fail else [])}
    workflow_executions.append(we)
    if fail:
        tasks.append({"id": uid(), "service": "fincrime", "type": "user_review", "state": "RESOLVED", "priority": "HIGH",
                      "staff_id": "", "assignee_id": uid(), "associated_ids": json.dumps([u["id"]]), "content": "{}",
                      "created_at": ts(created + timedelta(minutes=5)), "last_updated_at": ts(created + timedelta(hours=6)), "resolution": "APPROVED"})
tasks.append({"id": uid(), "service": "support", "type": "escalation", "state": "OPEN", "priority": "LOW", "staff_id": uid(),
              "assignee_id": "", "associated_ids": json.dumps([users[3]["id"]]), "content": "{}",
              "created_at": ts(AS_OF - timedelta(days=2)), "last_updated_at": ts(AS_OF - timedelta(days=2)), "resolution": ""})

# ----------------------------------------------------------------------------- amplitude
events = []
devices_shared = uid()
for i, u in enumerate(users[:40]):
    device = uid() if i != 1 else devices_shared  # EDGE CASE: shared device with two users
    signup_start = rand_ts(START, AS_OF - timedelta(days=3))
    country = u["sender_country"]
    base = {"device_id": device, "platform": random.choice(["iOS", "Android"]), "os_name": "mobile", "country": country,
            "city": "London", "app_version": "5.2.0", "session_id": random.randint(10**12, 10**13)}
    def ev(etype, at, with_user=True, props=None):
        return {"event_id": uid(), "user_id": u["id"] if with_user else "", **base, "event_type": etype, "event_time": ts(at),
                "event_properties": json.dumps(props or {}), "user_properties": json.dumps({"account_status": u["status"]}),
                "server_upload_time": ts(at + timedelta(seconds=5)), "_fivetran_synced": ts(AS_OF.replace(hour=6, minute=10))}
    events.append(ev("app.opened", signup_start - timedelta(minutes=2), with_user=False))
    events.append(ev("sign_up.started", signup_start, with_user=False))  # anonymous before account exists
    if random.random() < 0.85:
        done = signup_start + timedelta(minutes=random.randint(2, 30))
        events.append(ev("sign_up.completed", done))
        if random.random() < 0.8:
            for step in (1, 2, 3):
                events.append(ev("kyc_step.completed", done + timedelta(minutes=10 * step), props={"step": step, "is_final_step": step == 3}))
            if random.random() < 0.6:
                events.append(ev("transaction.completed", done + timedelta(hours=random.randint(1, 200))))
    elif i == 2:
        pass
if True:  # second user on the shared device
    u2 = users[45]
    events.append({"event_id": uid(), "user_id": u2["id"], "device_id": devices_shared, "platform": "Android", "os_name": "mobile",
                   "country": "GB", "city": "Leeds", "app_version": "5.2.0", "session_id": 999, "event_type": "sign_up.completed",
                   "event_time": ts(AS_OF - timedelta(days=5)), "event_properties": "{}", "user_properties": "{}",
                   "server_upload_time": ts(AS_OF - timedelta(days=5)), "_fivetran_synced": ts(AS_OF.replace(hour=6, minute=10))})

# ----------------------------------------------------------------------------- reference FX (weekday only: weekend gaps on purpose)
fx = []
d = (START - timedelta(days=10)).date()
while d <= AS_OF.date():
    if d.weekday() < 5:
        for cur, rate in (("GBP", 1.30), ("EUR", 1.10)):
            fx.append({"rate_date": d.isoformat(), "currency": cur, "usd_per_unit": round(rate + random.uniform(-0.01, 0.01), 6), "rate_source": "SYNTHETIC_TEST_FEED"})
    d += timedelta(days=1)

write("payments", "users", user_log)
write("payments", "users_account", cdc(accounts))
write("payments", "transactions_transaction", tx_log)
write("payments", "transactions_collection", cdc(collections) + cdc(deleted_children["collections"], "DELETE"))
write("payments", "transactions_disbursement", cdc(disbursements) + cdc(deleted_children["disbursements"], "DELETE"))
write("payments", "disbursement_attempts", cdc(attempts) + cdc(deleted_children["attempts"], "DELETE"))
write("payments", "transactions_recipient", cdc(recipients))
write("payments", "transactions_recipient_account", cdc(recipient_accounts))
write("payments", "tasks_task", cdc(tasks))
write("fincrime", "rules", cdc(rules))
write("fincrime", "workflows", cdc(workflows))
write("fincrime", "workflow_executions", cdc(workflow_executions))
write("fincrime", "rule_executions", cdc(rule_executions))
write("fincrime", "rule_execution_reviews", cdc(reviews))
write("amplitude", "events", events)
write("reference", "daily_fx_rates", fx)
