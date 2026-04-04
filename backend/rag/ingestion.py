"""
ingestion.py — Document ingestion pipeline for the RAG knowledge base.

================================================================================
📖 DEEP DIVE: How RAG Ingestion Works
================================================================================

Step 1 — LOAD: Read PDF/markdown files into Python Document objects
Step 2 — CHUNK: Split large docs into smaller pieces (~1000 tokens each)
    Why chunk? Because embedding models have token limits.
    Also, smaller chunks = more precise retrieval.
    We use overlap (150 tokens) so context isn't lost at chunk boundaries.
Step 3 — EMBED: Convert each chunk into a vector (list of ~1536 numbers)
    A vector captures the SEMANTIC MEANING of the text.
    "Rice plant disease" and "paddy crop infection" → similar vectors
    even though they share no words. This is the magic of embeddings.
Step 4 — STORE: Save vectors to pgvector (PostgreSQL with vector extension)
    pgvector can do extremely fast similarity search on millions of vectors.

At query time (see retriever.py):
    Query → embed → find nearest vectors → return those chunks → AI answers
================================================================================
"""

import os
import logging
from pathlib import Path
from typing import Optional

from langchain_community.document_loaders import (
    DirectoryLoader,
    PyPDFLoader,
    TextLoader,
    UnstructuredMarkdownLoader,
)
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_postgres import PGVector
from langchain_anthropic import AnthropicEmbeddings  # Uses Voyage embeddings via Anthropic

from config import settings

logger = logging.getLogger(__name__)


# ── Embedding Model ──────────────────────────────────────────────────────────
# Voyage-3 is Anthropic's embedding model.
# It converts text → 1024-dimensional vector.
# "voyage-3" is optimized for retrieval tasks.
def get_embeddings():
    return AnthropicEmbeddings(
        model="voyage-3",
        anthropic_api_key=settings.anthropic_api_key,
    )


# ── Vector Store Factory ─────────────────────────────────────────────────────
def get_vectorstore(collection_name: str) -> PGVector:
    """
    Get (or create) a pgvector collection.

    Each collection is a separate "namespace" in our vector DB:
    - crop_guides: Planting, fertilizer, variety guides
    - pest_library: Disease and pest information
    - govt_schemes: Government scheme documents

    Args:
        collection_name: "crop_guides" | "pest_library" | "govt_schemes"
    """
    return PGVector(
        embeddings=get_embeddings(),
        collection_name=collection_name,
        connection=settings.postgres_url,
        use_jsonb=True,  # Store metadata as JSONB for filtering
    )


# ── Main Ingestion Function ──────────────────────────────────────────────────
async def ingest_knowledge_base(
    data_dir: str,
    collection: str,
    chunk_size: int = 1000,
    chunk_overlap: int = 150,
    reset: bool = False,
) -> dict:
    """
    Ingest all documents from a directory into the vector store.

    Args:
        data_dir: Directory path containing PDF/markdown files
        collection: Vector store collection name
        chunk_size: Tokens per chunk (1000 is a good default)
        chunk_overlap: Overlap between chunks to preserve context
        reset: If True, delete existing vectors before ingesting

    Returns:
        Summary dict with counts and status
    """
    data_path = Path(data_dir)
    if not data_path.exists():
        logger.warning(f"Data directory not found: {data_dir}")
        return {"error": f"Directory {data_dir} does not exist", "chunks_ingested": 0}

    logger.info(f"Starting ingestion: {collection} ← {data_dir}")

    # ── Step 1: Load documents ────────────────────────────────────────────────
    docs = []

    # Load PDFs
    pdf_files = list(data_path.glob("**/*.pdf"))
    if pdf_files:
        pdf_loader = DirectoryLoader(
            str(data_path),
            glob="**/*.pdf",
            loader_cls=PyPDFLoader,
            show_progress=True,
        )
        docs.extend(pdf_loader.load())
        logger.info(f"Loaded {len(pdf_files)} PDF files")

    # Load Markdown files
    md_files = list(data_path.glob("**/*.md"))
    if md_files:
        md_loader = DirectoryLoader(
            str(data_path),
            glob="**/*.md",
            loader_cls=TextLoader,
            show_progress=True,
        )
        docs.extend(md_loader.load())
        logger.info(f"Loaded {len(md_files)} markdown files")

    # Load plain text files
    txt_files = list(data_path.glob("**/*.txt"))
    if txt_files:
        txt_loader = DirectoryLoader(
            str(data_path),
            glob="**/*.txt",
            loader_cls=TextLoader,
        )
        docs.extend(txt_loader.load())

    if not docs:
        logger.warning(f"No documents found in {data_dir}")
        return {"error": "No documents found", "chunks_ingested": 0}

    logger.info(f"Total documents loaded: {len(docs)}")

    # ── Step 2: Add metadata ───────────────────────────────────────────────────
    # Metadata is stored alongside each chunk in pgvector.
    # We can filter by metadata at query time (e.g., only search crop_guides).
    for doc in docs:
        doc.metadata["collection"] = collection
        doc.metadata["ingested_at"] = str(__import__("datetime").datetime.now())
        # Normalize source path for display
        if "source" in doc.metadata:
            doc.metadata["source"] = Path(doc.metadata["source"]).name

    # ── Step 3: Chunk documents ───────────────────────────────────────────────
    # RecursiveCharacterTextSplitter tries to split at natural boundaries:
    # paragraphs → sentences → words → characters
    # This preserves semantic coherence better than fixed-size splits.
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        length_function=len,
        separators=["\n\n", "\n", ". ", " ", ""],  # Try these in order
    )

    chunks = splitter.split_documents(docs)
    logger.info(f"Created {len(chunks)} chunks from {len(docs)} documents")

    # ── Step 4: Embed and store in pgvector ───────────────────────────────────
    # This is the expensive step — each chunk gets sent to the embedding API.
    # For 1000 chunks: ~$0.02 with Voyage-3. Very cheap.
    vectorstore = get_vectorstore(collection)

    if reset:
        # Delete existing collection before re-ingesting
        logger.info(f"Resetting collection: {collection}")
        vectorstore.delete_collection()
        vectorstore = get_vectorstore(collection)

    # Add in batches to avoid API rate limits
    batch_size = 100
    total_added = 0

    for i in range(0, len(chunks), batch_size):
        batch = chunks[i:i + batch_size]
        vectorstore.add_documents(batch)
        total_added += len(batch)
        logger.info(f"Ingested batch {i//batch_size + 1}: {total_added}/{len(chunks)} chunks")

    logger.info(f"✅ Ingestion complete: {total_added} chunks in '{collection}'")

    return {
        "collection": collection,
        "documents_loaded": len(docs),
        "chunks_ingested": total_added,
        "chunk_size": chunk_size,
        "chunk_overlap": chunk_overlap,
        "status": "success",
    }


# ── Sample Knowledge Base Content ─────────────────────────────────────────────
# These are example documents that get seeded if the data directories are empty.
# In production, you'd replace these with real PDFs from ICAR, govt portals, etc.

SAMPLE_CROP_GUIDE = """
# Tomato Cultivation Guide — Telangana Region

## Variety Selection
For Telangana's climate, the following varieties are recommended:
- **Arka Rakshak**: Resistant to TYLCV virus, suitable for Kharif season
- **Pusa Rohini**: Good for Rabi season, high yield potential
- **Namdhari 4266**: Hybrid, excellent shelf life for market transport

## Sowing Calendar
- Kharif sowing: June-July (transplant in July-August)
- Rabi sowing: October-November (transplant in November-December)

## Soil Requirements
- Well-drained sandy loam soil preferred
- pH range: 6.0-7.0
- Avoid waterlogging — tomatoes are highly susceptible to root rot

## Fertilizer Schedule
- Basal dose (at transplanting): 30kg N + 60kg P2O5 + 60kg K2O per hectare
- Top dressing at 30 days: 30kg N per hectare
- Top dressing at 60 days: 30kg N per hectare
- Micronutrients: Zinc sulfate 25kg/ha if zinc deficiency observed

## Irrigation
- Drip irrigation recommended — saves 40% water compared to flood irrigation
- Critical periods: flowering, fruit set, and fruit development
- Avoid waterlogging especially during monsoon
- Irrigation interval: 3-4 days in summer, 6-7 days in winter
"""

SAMPLE_PEST_GUIDE = """
# Tomato Early Blight — Disease Guide

## Disease Name
Early Blight (Alternaria blight)
Causal organism: Alternaria solani (fungal pathogen)

## Symptoms
- Dark brown to black spots with concentric rings (target board pattern)
- Yellow halo surrounding spots
- Lower/older leaves affected first, progresses upward
- In severe cases: complete defoliation
- Stem lesions: dark brown, elongated spots
- Fruit symptoms: dark, sunken lesions near stem end

## Favorable Conditions
- High humidity (>80%) combined with moderate temperature (24-28°C)
- Warm days and cool nights
- Overhead irrigation or frequent rain
- Plant stress (nutrient deficiency, drought)

## Identification vs. Other Diseases
- Early blight: Target ring pattern, older leaves first
- Late blight (Phytophthora): Water-soaked lesions, white sporulation on underside
- Septoria leaf spot: Small spots with dark border, white center

## Management
### Cultural Practices
1. Use certified disease-free seeds
2. Crop rotation — avoid planting tomato/potato family for 3 years
3. Remove and destroy infected plant debris
4. Avoid overhead irrigation — use drip

### Chemical Management
- Mancozeb 75% WP @ 2.5g/liter — spray every 10-14 days preventively
- Copper oxychloride 50% WP @ 3g/liter — at first sign of disease
- Iprodione 50% WP @ 1g/liter — for severe infection
- Azoxystrobin 23% SC @ 1ml/liter — systemic, good for wet conditions

### Biological Control
- Trichoderma viride @ 5g/liter — soil drench at transplanting
- Pseudomonas fluorescens — foliar spray

## Economic Threshold Level
Initiate spray when 10% of plants show symptoms.

## Spray Calendar
- Preventive sprays from 15-20 days after transplanting
- Continue at 10-14 day intervals through fruit development
"""

SAMPLE_SCHEME_GUIDE = """
# PM-KISAN Scheme — Complete Guide for Farmers

## Scheme Overview
PM-KISAN (Pradhan Mantri Kisan Samman Nidhi) provides income support of
₹6,000 per year to all eligible farmer families across India.

## Benefit Structure
- Total annual benefit: ₹6,000
- Installment 1: ₹2,000 (April-July)
- Installment 2: ₹2,000 (August-November)
- Installment 3: ₹2,000 (December-March)
- Transfer mode: Direct Bank Transfer (DBT) to registered bank account

## Eligibility Criteria
### Who is Eligible
- All landholding farmer families (even tenants with valid land records)
- Small, marginal, and large farmers — no upper land limit
- Both husband and wife can register (as separate landholders)

### Who is NOT Eligible
- Former/serving government employees
- Income tax payers
- Professionals: Doctors, engineers, lawyers, CAs (and family members)
- Former/serving MPs, MLAs, Ministers
- Institutional landholders

## Required Documents
1. Aadhaar card (mandatory for verification)
2. Land records / Khatauni / Patta
3. Bank account linked to Aadhaar
4. Mobile number (for OTP verification)

## How to Apply
### Option 1 — Online
1. Visit https://pmkisan.gov.in
2. Click "Farmer Corner" → "New Farmer Registration"
3. Enter Aadhaar number and captcha
4. Fill in personal details, bank details, land details
5. Submit — verification takes 2-4 weeks

### Option 2 — Through CSC (Common Service Centre)
1. Visit your nearest Citizen Service Centre
2. Carry all original documents
3. The CSC operator will fill the form for you (nominal fee: ₹30-50)

### Option 3 — Through Agriculture Department
1. Visit block-level agriculture office
2. Agriculture officer will register on your behalf

## Status Check
- Visit pmkisan.gov.in → Beneficiary Status
- Enter Aadhaar/mobile/bank account number
- Check installment payment status

## Common Issues and Solutions
1. **Payment not received**: Check bank account linked to Aadhaar in NPCI mapper
2. **Aadhaar mismatch**: Update name in Aadhaar or bank to match land records
3. **Land record dispute**: Resolve at tehsildar office before registration
"""


async def seed_sample_data():
    """
    Seed the knowledge base with sample documents.
    Run this when the data directories are empty (first-time setup).
    """
    base_dir = Path(__file__).parent / "data"

    # Write sample documents
    samples = {
        "crop_guides/tomato_guide.md": SAMPLE_CROP_GUIDE,
        "pest_library/early_blight.md": SAMPLE_PEST_GUIDE,
        "govt_schemes/pm_kisan_guide.md": SAMPLE_SCHEME_GUIDE,
    }

    for rel_path, content in samples.items():
        file_path = base_dir / rel_path
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_text(content)
        logger.info(f"Created sample: {file_path}")

    # Ingest each collection
    results = {}
    for collection in ["crop_guides", "pest_library", "govt_schemes"]:
        result = await ingest_knowledge_base(
            data_dir=str(base_dir / collection),
            collection=collection,
        )
        results[collection] = result

    return results
