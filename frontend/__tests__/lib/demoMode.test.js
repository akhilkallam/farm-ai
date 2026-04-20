import { getDemoResponse } from '@/lib/demoMode'

test('returns crop_advisor agent for crop keyword', () => {
  const result = getDemoResponse('which crop should I plant?')
  expect(result.agent).toBe('crop_advisor')
  expect(typeof result.text).toBe('string')
})

test('returns pest_detector agent for disease keyword', () => {
  const result = getDemoResponse('my tomato has brown spots disease')
  expect(result.agent).toBe('pest_detector')
})

test('returns market_analyst agent for price keyword', () => {
  const result = getDemoResponse('what is the current price at mandi?')
  expect(result.agent).toBe('market_analyst')
})

test('returns irrigation_planner agent for water keyword', () => {
  const result = getDemoResponse('should I irrigate today?')
  expect(result.agent).toBe('irrigation_planner')
})

test('returns scheme_navigator agent for scheme keyword', () => {
  const result = getDemoResponse('am I eligible for government scheme PM-KISAN?')
  expect(result.agent).toBe('scheme_navigator')
})

test('returns supervisor agent for unrecognized input', () => {
  const result = getDemoResponse('xyzzy unfamiliar topic')
  expect(result.agent).toBe('supervisor')
})

test('returned text is a non-empty string', () => {
  const result = getDemoResponse('hello')
  expect(result.text.length).toBeGreaterThan(10)
})
