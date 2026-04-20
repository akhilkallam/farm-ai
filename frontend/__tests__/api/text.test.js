import { POST } from '@/app/api/text/route'

beforeEach(() => {
  global.fetch = jest.fn()
  process.env.BFF_URL = 'http://test-bff:8002'
})

afterEach(() => jest.resetAllMocks())

test('POST proxies request to BFF /text/chat', async () => {
  global.fetch.mockResolvedValue({
    status: 200,
    json: async () => ({ text_response: 'Use drip irrigation', agent_used: 'irrigation_planner' }),
  })

  const req = new Request('http://localhost/api/text', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ farmer_id: 'farmer-1', text: 'How to water wheat?', language: 'hi' }),
  })

  const resp = await POST(req)
  const data = await resp.json()

  expect(global.fetch).toHaveBeenCalledWith(
    'http://test-bff:8002/text/chat',
    expect.objectContaining({ method: 'POST' })
  )
  expect(data.text_response).toBe('Use drip irrigation')
  expect(resp.status).toBe(200)
})
