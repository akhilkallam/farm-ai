import { POST as syncPushPOST } from '@/app/api/sync/push/route'
import { GET as syncPullGET } from '@/app/api/sync/pull/[farmerId]/route'

beforeEach(() => {
  global.fetch = jest.fn()
  process.env.BFF_URL = 'http://test-bff:8002'
})

afterEach(() => jest.resetAllMocks())

test('sync/push proxies batch to BFF', async () => {
  global.fetch.mockResolvedValue({
    status: 200,
    json: async () => ({ results: [{ id: 'req-1', success: true }] }),
  })

  const req = new Request('http://localhost/api/sync/push', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ requests: [{ id: 'req-1', text: 'hello', farmer_id: 'f1', language: 'hi', queued_at: '2026-01-01T00:00:00Z' }] }),
  })

  const resp = await syncPushPOST(req)
  const data = await resp.json()

  expect(global.fetch).toHaveBeenCalledWith(
    'http://test-bff:8002/sync/push',
    expect.objectContaining({ method: 'POST' })
  )
  expect(data.results[0].success).toBe(true)
})

test('sync/pull proxies to BFF with correct farmerId', async () => {
  global.fetch.mockResolvedValue({
    status: 200,
    json: async () => ({ farmer_profile: { name: 'Raju' }, recent_conversations: [] }),
  })

  const req = new Request('http://localhost/api/sync/pull/farmer-1')
  const resp = await syncPullGET(req, { params: { farmerId: 'farmer-1' } })
  const data = await resp.json()

  expect(global.fetch).toHaveBeenCalledWith('http://test-bff:8002/sync/pull/farmer-1')
  expect(data.farmer_profile.name).toBe('Raju')
})
