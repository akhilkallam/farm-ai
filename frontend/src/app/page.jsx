'use client'
import { useState, useEffect } from 'react'
import ChatScreen from '@/components/chat/ChatScreen'
import FarmStats from '@/components/dashboard/FarmStats'
import AgentStatus from '@/components/dashboard/AgentStatus'

export default function FarmAIApp() {
  const [activeTab, setActiveTab] = useState('chat')

  useEffect(() => {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/sw.js').catch(() => {
        // SW registration is best-effort — don't throw if it fails
      })
    }
  }, [])

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50 flex flex-col">
      <header className="bg-green-700 text-white px-4 py-3 shadow-md">
        <div className="max-w-4xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="text-2xl">🌱</div>
            <div>
              <h1 className="font-bold text-lg leading-tight">FarmAI</h1>
              <p className="text-green-200 text-xs">Powered by Claude + MCP + RAG + Multi-Agent</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-green-300 rounded-full animate-pulse" />
            <span className="text-xs text-green-200">All agents active</span>
          </div>
        </div>
      </header>

      <div className="bg-white border-b border-gray-200 px-4">
        <div className="max-w-4xl mx-auto flex gap-4">
          {['chat', 'dashboard'].map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`py-3 px-2 text-sm font-medium border-b-2 transition-colors ${
                activeTab === tab
                  ? 'border-green-600 text-green-700'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              {tab === 'chat' ? '💬 Chat' : '📊 Dashboard'}
            </button>
          ))}
        </div>
      </div>

      {activeTab === 'chat' ? (
        <ChatScreen />
      ) : (
        <div className="flex-1 max-w-4xl mx-auto w-full px-4 py-4">
          <FarmStats />
          <AgentStatus />
        </div>
      )}
    </div>
  )
}
