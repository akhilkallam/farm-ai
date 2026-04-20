export async function POST(request) {
  const BFF_URL = process.env.BFF_URL || 'http://localhost:8002'
  const body = await request.json()
  const resp = await fetch(`${BFF_URL}/text/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  const data = await resp.json()
  return Response.json(data, { status: resp.status })
}
