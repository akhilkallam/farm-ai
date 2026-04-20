export async function POST(request) {
  const BFF_URL = process.env.BFF_URL || 'http://localhost:8002'
  const formData = await request.formData()
  const resp = await fetch(`${BFF_URL}/voice/chat`, {
    method: 'POST',
    body: formData,
  })
  const data = await resp.json()
  return Response.json(data, { status: resp.status })
}
