import os
import asyncpg
from fastapi import FastAPI, Request, HTTPException, status
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Allow local frontend; tighten in production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="./frontend/static"), name="static")

ADMIN_USER = os.environ.get("APP_ADMIN_USER", "admin")
ADMIN_PASSWORD = os.environ.get("APP_ADMIN_PASSWORD", "P@ssw0rd!")
SESSION_TOKEN = "demo-session-token"


@app.get("/", response_class=HTMLResponse)
async def index():
    with open("frontend/index.html", "r") as f:
        return HTMLResponse(f.read())


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/db-check")
async def db_check():
    dsn = os.environ.get("DATABASE_URL")
    if not dsn:
        return {"error": "DATABASE_URL not configured"}
    conn = await asyncpg.connect(dsn)
    try:
        version = await conn.fetchval("SELECT version()")
    finally:
        await conn.close()
    return {"db_version": version}


@app.post("/login")
async def login(request: Request):
    payload = await request.json()
    username = payload.get("username")
    password = payload.get("password")
    if username == ADMIN_USER and password == ADMIN_PASSWORD:
        return {
            "token": SESSION_TOKEN,
            "user": {"name": "SkyPoint Clinician", "role": "Provider"},
        }
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")


def authorized(request: Request):
    auth = request.headers.get("Authorization", "")
    if auth != f"Bearer {SESSION_TOKEN}":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")


@app.get("/dashboard")
async def dashboard(request: Request):
    authorized(request)
    return {
        "patients": 1284,
        "openAppointments": 18,
        "criticalAlerts": 3,
        "averageWaitMins": 12,
    }


@app.get("/appointments")
async def appointments(request: Request):
    authorized(request)
    return {
        "appointments": [
            {"time": "09:00", "patient": "Mar�a Santos", "status": "Check-in"},
            {"time": "09:30", "patient": "James Lee", "status": "Pending"},
            {"time": "10:15", "patient": "Aisha Khan", "status": "Confirmed"},
        ]
    }


@app.get("/patients")
async def list_patients(request: Request):
    authorized(request)
    dsn = os.environ.get("DATABASE_URL")
    sample = [{"id": 1, "name": "John Doe", "dob": "1980-01-01", "status": "Active"}]
    if not dsn:
        return {"patients": sample}
    conn = await asyncpg.connect(dsn)
    try:
        rows = await conn.fetch("SELECT id, name, dob FROM patients ORDER BY id LIMIT 100")
        patients = [
            {"id": r["id"], "name": r["name"], "dob": str(r["dob"]), "status": "Active"}
            for r in rows
        ]
    except Exception:
        patients = sample
    finally:
        await conn.close()
    return {"patients": patients}
