export async function GET(request, { params }) {
  const BFF_URL = process.env.BFF_URL || 'http://localhost:8002'
  const resp = await fetch(`${BFF_URL}/sync/pull/${params.farmerId}`)
  const data = await resp.json()
  return Response.json(data, { status: resp.status })
}
