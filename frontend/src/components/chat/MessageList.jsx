'use client'
import { useRef, useEffect } from 'react'
import MessageBubble from './MessageBubble'
import ThinkingBubble from './ThinkingBubble'

export default function MessageList({ messages, loading }) {
  const endRef = useRef(null)

  useEffect(() => {
    if (endRef.current && typeof endRef.current.scrollIntoView === 'function') {
      endRef.current.scrollIntoView({ behavior: 'smooth' })
    }
  }, [messages, loading])

  return (
    <div
      className="flex-1 overflow-y-auto py-2 space-y-1 min-h-0"
      style={{ maxHeight: 'calc(100vh - 280px)' }}
    >
      {messages.map((msg) => (
        <MessageBubble key={msg.id} msg={msg} />
      ))}
      {loading && <ThinkingBubble />}
      <div ref={endRef} />
    </div>
  )
}
