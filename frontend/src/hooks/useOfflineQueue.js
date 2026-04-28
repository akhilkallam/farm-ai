'use client'
import { useState, useEffect, useCallback } from 'react'
import { createStore, set, del, entries } from 'idb-keyval'
import { syncPush } from '@/lib/api'

const queueStore = typeof window !== 'undefined'
  ? createStore('farm-ai-offline', 'queue')
  : null

export function useOfflineQueue(farmerId) {
  const [queueSize, setQueueSize] = useState(0)

  const refreshSize = useCallback(async () => {
    if (!queueStore) return
    const all = await entries(queueStore)
    setQueueSize(all.filter(([, v]) => v.status === 'pending').length)
  }, [])

  useEffect(() => {
    refreshSize()
  }, [refreshSize])

  const addToQueue = useCallback(async ({ text, language }) => {
    if (!queueStore) return
    const id = `oq:${Date.now()}-${Math.random().toString(36).slice(2)}`
    await set(id, {
      id,
      text,
      farmer_id: farmerId,
      language,
      queued_at: new Date().toISOString(),
      status: 'pending',
    }, queueStore)
    setQueueSize((n) => n + 1)
  }, [farmerId])

  const flushQueue = useCallback(async () => {
    if (!queueStore || !navigator.onLine) return
    const all = await entries(queueStore)
    const pending = all
      .filter(([, v]) => v.status === 'pending')
      .map(([, v]) => v)
    if (pending.length === 0) return

    try {
      const { results } = await syncPush(pending)
      for (const result of results) {
        if (result.success) await del(result.id, queueStore)
      }
    } catch {
      // Will retry on next flush
    }
    await refreshSize()
  }, [refreshSize])

  useEffect(() => {
    window.addEventListener('online', flushQueue)
    return () => window.removeEventListener('online', flushQueue)
  }, [flushQueue])

  return { addToQueue, flushQueue, queueSize }
}
