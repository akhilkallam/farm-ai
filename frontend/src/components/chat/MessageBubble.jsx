'use client'
import { AGENT_COLORS, AGENT_ICONS } from '@/lib/agentConfig'

export default function MessageBubble({ msg }) {
  const isUser = msg.role === 'user'

  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'} mb-4`}>
      {!isUser && (
        <div className="w-8 h-8 rounded-full bg-green-500 flex items-center justify-center text-white text-sm mr-2 flex-shrink-0 mt-1">
          🌱
        </div>
      )}
      <div className={`max-w-2xl ${isUser ? 'items-end' : 'items-start'} flex flex-col`}>
        <div
          className={`px-4 py-3 rounded-2xl ${
            isUser
              ? 'bg-green-600 text-white rounded-tr-sm'
              : 'bg-white text-gray-800 rounded-tl-sm shadow-sm border border-gray-100'
          }`}
        >
          <p className="text-sm leading-relaxed whitespace-pre-wrap">{msg.content}</p>
          {msg.audioUrl && (
            <audio
              className="mt-2 w-full"
              controls
              src={msg.audioUrl}
            />
          )}
        </div>
        {msg.agent && (
          <div className="flex items-center gap-1 mt-1 ml-1">
            <span
              className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                AGENT_COLORS[msg.agent] || 'bg-gray-100 text-gray-600'
              }`}
            >
              {AGENT_ICONS[msg.agent]} {msg.agent.replace(/_/g, ' ')}
            </span>
          </div>
        )}
        <span className="text-xs text-gray-400 mt-1 px-1">
          {new Date(msg.timestamp).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}
        </span>
      </div>
      {isUser && (
        <div className="w-8 h-8 rounded-full bg-green-700 flex items-center justify-center text-white text-sm ml-2 flex-shrink-0 mt-1">
          👨‍🌾
        </div>
      )}
    </div>
  )
}
