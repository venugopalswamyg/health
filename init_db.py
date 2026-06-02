import os
import asyncio
import asyncpg
from datetime import date

async def init():
    dsn = os.environ.get("DATABASE_URL")
    if not dsn:
        print("DATABASE_URL not set; skipping DB init")
        return
    conn = await asyncpg.connect(dsn)
    try:
        await conn.execute('''
        CREATE TABLE IF NOT EXISTS patients (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            dob DATE
        );
        ''')
        # seed sample
        await conn.execute(
            "INSERT INTO patients (name, dob) VALUES ($1, $2) ON CONFLICT DO NOTHING;",
            "John Doe",
            date.fromisoformat("1980-01-01"),
        )
        print("DB initialized")
    finally:
        await conn.close()

if __name__ == '__main__':
    asyncio.run(init())
