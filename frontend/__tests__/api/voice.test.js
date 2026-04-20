import { POST } from '@/app/api/voice/route'

beforeEach(() => {
  global.fetch = jest.fn()
  process.env.BFF_URL = 'http://test-bff:8002'
})

afterEach(() => jest.resetAllMocks())

test('POST proxies FormData to BFF /voice/chat', async () => {
  global.fetch.mockResolvedValue({
    status: 200,
    json: async () => ({
      text_response: 'Use neem oil',
      translated_response: 'नीम तेल का उपयोग करें',
      audio_url: '/audio/test.mp3',
      agent_used: 'pest_detector',
      language_detected: 'hi',
      queued: false,
    }),
  })

  const formData = new FormData()
  formData.append('farmer_id', 'farmer-1')
  formData.append('audio', new Blob(['audio'], { type: 'audio/m4a' }), 'recording.m4a')

  const req = new Request('http://localhost/api/voice', {
    method: 'POST',
    body: formData,
  })

  const resp = await POST(req)
  const data = await resp.json()

  expect(global.fetch).toHaveBeenCalledWith(
    'http://test-bff:8002/voice/chat',
    expect.objectContaining({ method: 'POST' })
  )
  expect(data.audio_url).toBe('/audio/test.mp3')
})
