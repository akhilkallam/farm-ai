"""
store.py — Farmer profile memory using PostgreSQL.

📖 LEARNING NOTE — Why "Memory" for AI agents?
    LLMs are stateless by default — every API call is a fresh start.
    If you ask "what crop did I mention last week?", Claude has no idea.

    Farmer Memory solves this by persisting:
    - Farmer profile (name, location, land, crops)
    - Conversation history (last 10 interactions)
    - Seasonal context (what they planted, what happened)

    This makes FarmAI feel like a knowledgeable advisor who KNOWS the farmer,
    not a chatbot that forgets everything after each message.

    Implementation: Simple PostgreSQL tables.
    In production: could add Redis for hot-cache of recent interactions.
"""

import json
import logging
from datetime import datetime
from typing import Optional, List

import asyncpg

from config import settings

logger = logging.getLogger(__name__)


class FarmerMemoryStore:
    """
    PostgreSQL-backed store for farmer profiles and interaction history.
    Uses asyncpg for non-blocking database access.
    """

    def __init__(self):
        self._pool: Optional[asyncpg.Pool] = None

    async def init(self):
        """Create connection pool."""
        self._pool = await asyncpg.create_pool(
            settings.postgres_url,
            min_size=2,
            max_size=10,
        )
        logger.info("FarmerMemoryStore initialized")

    async def close(self):
        if self._pool:
            await self._pool.close()

    # ── Farmer Profile ─────────────────────────────────────────────────────────

    async def get_farmer(self, farmer_id: str) -> Optional[dict]:
        """Retrieve farmer profile by ID."""
        async with self._pool.acquire() as conn:
            row = await conn.fetchrow(
                "SELECT * FROM farmer_profiles WHERE id = $1", farmer_id
            )
            return dict(row) if row else None

    async def create_farmer(self, farmer_data: dict) -> dict:
        """Create a new farmer profile."""
        async with self._pool.acquire() as conn:
            row = await conn.fetchrow("""
                INSERT INTO farmer_profiles
                    (name, phone, location, state, land_acres, current_crops,
                     irrigation_type, category)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                RETURNING *
            """,
                farmer_data.get("name"),
                farmer_data.get("phone"),
                farmer_data.get("location"),
                farmer_data.get("state"),
                float(farmer_data.get("land_acres", 5)),
                farmer_data.get("current_crops", []),
                farmer_data.get("irrigation_type", "flood"),
                farmer_data.get("category", "small"),
            )
            return dict(row)

    async def update_farmer(self, farmer_id: str, updates: dict) -> Optional[dict]:
        """Update farmer profile fields."""
        # Build dynamic UPDATE query
        fields = []
        values = []
        for i, (key, value) in enumerate(updates.items(), 1):
            fields.append(f"{key} = ${i}")
            values.append(value)
        values.append(farmer_id)

        query = f"UPDATE farmer_profiles SET {', '.join(fields)} WHERE id = ${len(values)} RETURNING *"
        async with self._pool.acquire() as conn:
            row = await conn.fetchrow(query, *values)
            return dict(row) if row else None

    # ── Interaction History ────────────────────────────────────────────────────

    async def save_interaction(
        self,
        farmer_id: str,
        query: str,
        response: str,
        agent_used: str = "unknown",
    ) -> None:
        """Save a farmer-AI interaction to history."""
        async with self._pool.acquire() as conn:
            await conn.execute("""
                INSERT INTO farm_history (farmer_id, query, response, agent_used)
                VALUES ($1, $2, $3, $4)
            """, farmer_id, query, response, agent_used)

    async def get_recent_history(
        self,
        farmer_id: str,
        limit: int = 10
    ) -> List[dict]:
        """Get recent interaction history for a farmer."""
        async with self._pool.acquire() as conn:
            rows = await conn.fetch("""
                SELECT query, response, agent_used, created_at
                FROM farm_history
                WHERE farmer_id = $1
                ORDER BY created_at DESC
                LIMIT $2
            """, farmer_id, limit)
            return [dict(row) for row in rows]

    # ── Context Builder ────────────────────────────────────────────────────────

    async def build_context(self, farmer_id: str) -> str:
        """
        Build a rich context string for injecting into agent prompts.

        This is what turns raw DB data into useful agent context.
        The agents receive this context and can tailor their responses
        to the specific farmer's situation.
        """
        farmer = await self.get_farmer(farmer_id)
        if not farmer:
            return "No farmer profile found. Using generic context."

        history = await self.get_recent_history(farmer_id, limit=5)

        # Format recent history
        history_text = ""
        if history:
            recent = history[:3]  # Last 3 interactions
            history_lines = []
            for h in recent:
                date_str = h["created_at"].strftime("%d %b") if h.get("created_at") else "Recently"
                history_lines.append(f"  [{date_str}] Q: {h['query'][:100]}...")
            history_text = "\nRecent interactions:\n" + "\n".join(history_lines)

        crops = farmer.get("current_crops") or ["Not specified"]
        if isinstance(crops, str):
            crops = [crops]

        return f"""
Farmer Profile:
  Name: {farmer.get('name', 'Farmer')}
  Location: {farmer.get('location', 'Not specified')}, {farmer.get('state', '')}
  Land: {farmer.get('land_acres', 'Unknown')} acres
  Current crops: {', '.join(crops)}
  Irrigation: {farmer.get('irrigation_type', 'Not specified')}
  Category: {farmer.get('category', 'small')} farmer
{history_text}
"""

    async def get_farmer_dict(self, farmer_id: str) -> dict:
        """Get farmer as a dict suitable for agent context."""
        farmer = await self.get_farmer(farmer_id)
        if not farmer:
            return {
                "name": "Farmer",
                "location": "India",
                "state": "unknown",
                "land_acres": 5,
                "current_crops": ["Unknown"],
                "irrigation_type": "flood",
                "category": "small",
            }

        crops = farmer.get("current_crops") or ["Unknown"]
        return {
            "name": farmer.get("name", "Farmer"),
            "location": farmer.get("location", "India"),
            "state": farmer.get("state", "unknown"),
            "land_acres": float(farmer.get("land_acres", 5)),
            "current_crops": crops if isinstance(crops, list) else [crops],
            "irrigation_type": farmer.get("irrigation_type", "flood"),
            "category": farmer.get("category", "small"),
        }


# Singleton instance
memory_store = FarmerMemoryStore()
