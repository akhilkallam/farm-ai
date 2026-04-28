import { sendText, sendVoice, syncPull, syncPush } from '@/lib/api'

beforeEach(() => {
  global.fetch = jest.fn()
})

afterEach(() => {
  jest.resetAllMocks()
})

test('sendText POSTs to /api/text with correct body', async () => {
  global.fetch.mockResolvedValue({
    ok: true,
    json: async () => ({ text_response: 'ok', agent_used: 'crop_advisor' }),
  })

  const result = await sendText('farmer-1', 'hello', 'hi')

  expect(global.fetch).toHaveBeenCalledWith('/api/text', expect.objectContaining({
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ farmer_id: 'farmer-1', text: 'hello', language: 'hi' }),
  }))
  expect(result.text_response).toBe('ok')
})

test('sendText defaults language to "hi"', async () => {
  global.fetch.mockResolvedValue({
    ok: true,
    json: async () => ({}),
  })

  await sendText('farmer-1', 'hello')

  const body = JSON.parse(global.fetch.mock.calls[0][1].body)
  expect(body.language).toBe('hi')
})

test('sendText throws on non-ok response', async () => {
  global.fetch.mockResolvedValue({ ok: false, status: 503 })
  await expect(sendText('f', 'x')).rejects.toThrow('503')
})

test('sendVoice POSTs FormData to /api/voice', async () => {
  global.fetch.mockResolvedValue({
    ok: true,
    json: async () => ({ audio_url: '/audio/test.mp3', text_response: 'ok' }),
  })

  const blob = new Blob(['audio'], { type: 'audio/m4a' })
  const result = await sendVoice('farmer-1', blob, 'hi')

  const [url, options] = global.fetch.mock.calls[0]
  expect(url).toBe('/api/voice')
  expect(options.method).toBe('POST')
  expect(options.body).toBeInstanceOf(FormData)
  expect(result.audio_url).toBe('/audio/test.mp3')
})

test('syncPull GETs /api/sync/pull/{farmerId}', async () => {
  global.fetch.mockResolvedValue({
    ok: true,
    json: async () => ({ farmer_profile: {}, recent_conversations: [] }),
  })

  await syncPull('farmer-1')

  expect(global.fetch).toHaveBeenCalledWith('/api/sync/pull/farmer-1')
})

test('syncPush POSTs batch to /api/sync/push', async () => {
  global.fetch.mockResolvedValue({
    ok: true,
    json: async () => ({ results: [] }),
  })

  const requests = [{ id: 'req-1', text: 'hello', farmer_id: 'f1', language: 'hi', queued_at: '2026-01-01' }]
  await syncPush(requests)

  const body = JSON.parse(global.fetch.mock.calls[0][1].body)
  expect(body.requests).toHaveLength(1)
  expect(body.requests[0].id).toBe('req-1')
})
