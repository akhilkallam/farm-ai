"""
pipeline.py — RAG query pipeline (the "R" and "G" parts of RAG).

================================================================================
📖 DEEP DIVE: The RAG Query Flow
================================================================================

After ingestion (ingestion.py), the query flow is:

1. EMBED QUERY: User's question → vector (same embedding model as ingestion)
2. SEARCH: Find top-K chunks with highest cosine similarity to query vector
3. RERANK (optional): Re-order results for relevance (we do simple top-K here)
4. AUGMENT: Stuff retrieved chunks into Claude's context as "context documents"
5. GENERATE: Claude answers the question using the retrieved context

The key insight: Claude's answer is GROUNDED in real documents.
It can't hallucinate facts that aren't in the retrieved chunks.
We also return source documents so farmers can verify info.

================================================================================
"""

import logging
from typing import Optional

from langchain_anthropic import ChatAnthropic
from langchain.prompts import ChatPromptTemplate
from langchain.schema import StrOutputParser
from langchain_core.runnables import RunnablePassthrough, RunnableParallel

from ingestion import get_vectorstore, get_embeddings
from config import settings

logger = logging.getLogger(__name__)

# ── RAG Prompt Templates ─────────────────────────────────────────────────────
# These are carefully designed prompts for each knowledge domain.
# Notice: we tell Claude to ONLY use the provided context and to admit
# when it doesn't know. This prevents hallucination.

CROP_ADVISOR_PROMPT = ChatPromptTemplate.from_template("""
You are FarmAI's crop advisory expert. Answer the farmer's question using ONLY
the information from the retrieved agricultural documents below.

If the documents don't contain enough information to fully answer the question,
say so clearly and suggest what additional info would help.

Retrieved Documents:
{context}

Farmer's Question: {question}

Guidelines:
- Be specific with quantities (kg/ha, litres/acre, days after sowing)
- Use simple language (assume the farmer may not be highly literate)
- If there are multiple options, rank them by cost-effectiveness
- Always mention the season context (Kharif/Rabi) if relevant
- Cite the document source when giving specific numbers

Answer:
""")

PEST_DETECTIVE_PROMPT = ChatPromptTemplate.from_template("""
You are FarmAI's plant pathology expert. Diagnose the farmer's pest or disease
problem using ONLY the retrieved pest library documents below.

Retrieved Disease/Pest Documents:
{context}

Farmer's Problem Description: {question}

Your diagnosis should include:
1. Most likely disease/pest (with confidence level: High/Medium/Low)
2. Key symptoms that match
3. Immediate action (what to do TODAY)
4. Treatment with specific products and doses
5. Preventive measures for future seasons

If the description matches multiple diseases, list them in order of likelihood.
Cite the document source for treatment recommendations.

Diagnosis:
""")

SCHEME_NAVIGATOR_PROMPT = ChatPromptTemplate.from_template("""
You are FarmAI's government scheme expert. Help the farmer understand and access
government programs using the scheme documents below.

Retrieved Scheme Documents:
{context}

Farmer's Query: {question}

Provide:
1. Which schemes are directly relevant
2. Step-by-step application process (in simple terms)
3. Exact documents needed
4. Where to go (online portal / office)
5. Important deadlines if any

Use simple, actionable language. The farmer should know EXACTLY what to do
after reading your response.

Response:
""")

PROMPTS = {
    "crop_guides": CROP_ADVISOR_PROMPT,
    "pest_library": PEST_DETECTIVE_PROMPT,
    "govt_schemes": SCHEME_NAVIGATOR_PROMPT,
}


# ── Context Formatter ─────────────────────────────────────────────────────────
def format_docs(docs: list) -> str:
    """
    Format retrieved documents into a string for the prompt.

    📖 NOTE: How we format context matters A LOT for quality.
    Including the source (filename) helps Claude cite properly
    and helps the farmer know where info comes from.
    """
    formatted = []
    for i, doc in enumerate(docs, 1):
        source = doc.metadata.get("source", "Unknown Source")
        formatted.append(
            f"--- Document {i} (Source: {source}) ---\n{doc.page_content}\n"
        )
    return "\n".join(formatted)


# ── RAG Chain Builder ─────────────────────────────────────────────────────────
def build_rag_chain(collection: str):
    """
    Build a complete RAG chain for a specific knowledge collection.

    📖 NOTE — LangChain LCEL (LangChain Expression Language):
    The | pipe operator chains steps together (like Unix pipes).
    This is declarative: you describe WHAT to do, not HOW.

        retriever | format_docs | prompt | llm | parser

    Each step's output becomes the next step's input.
    LCEL also handles async, streaming, and batching automatically.

    Args:
        collection: "crop_guides" | "pest_library" | "govt_schemes"

    Returns:
        A callable chain: chain.invoke({"question": "..."}) → str
    """
    # Get the vector store for this collection
    vectorstore = get_vectorstore(collection)

    # Create a retriever — this does the similarity search
    retriever = vectorstore.as_retriever(
        search_type="similarity",  # Cosine similarity search
        search_kwargs={
            "k": 5,  # Return top 5 most relevant chunks
            # Optional: filter by metadata
            # "filter": {"collection": collection}
        }
    )

    # Get the right prompt for this collection
    prompt = PROMPTS.get(collection, CROP_ADVISOR_PROMPT)

    # Claude Sonnet — good balance of speed and quality for RAG
    llm = ChatAnthropic(
        model=settings.claude_model,
        anthropic_api_key=settings.anthropic_api_key,
        temperature=0.1,  # Low temperature = more factual, less creative
        max_tokens=2048,
    )

    # ── Build the chain ───────────────────────────────────────────────────────
    # RunnableParallel runs retrieval and question passthrough simultaneously
    rag_chain = (
        RunnableParallel({
            "context": retriever | format_docs,  # Retrieve docs → format as string
            "question": RunnablePassthrough(),    # Pass question through unchanged
        })
        | prompt                                  # Fill prompt template
        | llm                                     # Generate with Claude
        | StrOutputParser()                       # Extract string from response
    )

    return rag_chain


# ── High-level Query Function ─────────────────────────────────────────────────
async def query_knowledge_base(
    question: str,
    collection: str,
    return_sources: bool = True,
) -> dict:
    """
    Query the RAG knowledge base and return answer with sources.

    Args:
        question: The farmer's question
        collection: Which knowledge base to search
        return_sources: Whether to return source document chunks

    Returns:
        {answer: str, sources: list, collection: str}
    """
    logger.info(f"RAG query: collection={collection}, question={question[:80]}...")

    vectorstore = get_vectorstore(collection)
    retriever = vectorstore.as_retriever(search_kwargs={"k": 5})

    # Retrieve relevant docs
    docs = await retriever.aget_relevant_documents(question)

    if not docs:
        return {
            "answer": (
                "I couldn't find specific information about this in my knowledge base. "
                "Please consult your local agriculture extension officer for advice."
            ),
            "sources": [],
            "collection": collection,
            "chunks_found": 0,
        }

    # Build and run chain
    chain = build_rag_chain(collection)
    answer = await chain.ainvoke(question)

    return {
        "answer": answer,
        "sources": [
            {
                "source": doc.metadata.get("source", "Unknown"),
                "excerpt": doc.page_content[:200] + "..." if len(doc.page_content) > 200 else doc.page_content,
            }
            for doc in docs
        ] if return_sources else [],
        "collection": collection,
        "chunks_found": len(docs),
    }


# ── Multi-Collection Search ───────────────────────────────────────────────────
async def search_all_collections(question: str) -> dict:
    """
    Search across all knowledge bases and return the best answer.
    Useful when we're not sure which collection has the answer.
    """
    collections = ["crop_guides", "pest_library", "govt_schemes"]
    results = {}

    for collection in collections:
        try:
            result = await query_knowledge_base(question, collection)
            results[collection] = result
        except Exception as e:
            logger.error(f"Error querying {collection}: {e}")
            results[collection] = {"error": str(e)}

    return results
