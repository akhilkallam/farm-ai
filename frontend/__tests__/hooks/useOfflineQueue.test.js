jest.mock('idb-keyval')
jest.mock('@/lib/api')

import { renderHook, act, waitFor } from '@testing-library/react'
import * as idbKeyval from 'idb-keyval'
import { syncPush } from '@/lib/api'

beforeEach(() => {
  jest.clearAllMocks()
  
  // Setup navigator.onLine
  Object.defineProperty(navigator, 'onLine', {
    writable: true,
    value: true,
    configurable: true,
  })
  
  // Setup default mocks
  idbKeyval.createStore.mockReturnValue('mock-store')
  idbKeyval.set.mockResolvedValue(undefined)
  idbKeyval.del.mockResolvedValue(undefined)
  idbKeyval.entries.mockResolvedValue([])
  syncPush.mockResolvedValue({ results: [] })
})

test('addToQueue stores item in IndexedDB', async () => {
  const { useOfflineQueue } = require('@/hooks/useOfflineQueue')
  const { result } = renderHook(() => useOfflineQueue('demo-farmer'))
  
  await act(async () => {
    await result.current.addToQueue({ text: 'test', language: 'hi' })
  })
  
  expect(idbKeyval.set).toHaveBeenCalledWith(
    expect.stringMatching(/^oq:/),
    expect.objectContaining({ text: 'test', language: 'hi', status: 'pending' }),
    'mock-store'
  )
})

test('flushQueue sends pending items to syncPush and removes them', async () => {
  const { useOfflineQueue } = require('@/hooks/useOfflineQueue')
  const pendingItem = { id: 'oq:abc', text: 'hello', farmer_id: 'demo-farmer', language: 'hi', queued_at: '2026-01-01T00:00:00Z', status: 'pending' }
  idbKeyval.entries.mockResolvedValue([['oq:abc', pendingItem]])
  syncPush.mockResolvedValue({ results: [{ id: 'oq:abc', success: true, response: { text_response: 'ok' } }] })

  const { result } = renderHook(() => useOfflineQueue('demo-farmer'))
  
  await act(async () => {
    await result.current.flushQueue()
  })

  expect(syncPush).toHaveBeenCalledWith([pendingItem])
  expect(idbKeyval.del).toHaveBeenCalledWith('oq:abc', 'mock-store')
})

test('queueSize reflects number of pending items', async () => {
  const { useOfflineQueue } = require('@/hooks/useOfflineQueue')
  const items = [
    ['oq:1', { status: 'pending' }],
    ['oq:2', { status: 'pending' }],
  ]
  idbKeyval.entries.mockResolvedValue(items)
  
  const { result } = renderHook(() => useOfflineQueue('demo-farmer'))
  
  await waitFor(() => {
    expect(result.current.queueSize).toBe(2)
  })
})
