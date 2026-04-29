'use client'
import { useState, useEffect } from 'react'
import MessageList from './MessageList'
import VoiceInput from './VoiceInput'
import { useFarmerProfile } from '@/hooks/useFarmerProfile'
import { useVoice } from '@/hooks/useVoice'
import { useOfflineQueue } from '@/hooks/useOfflineQueue'
import { sendText, sendVoice } from '@/lib/api'
import { getDemoResponse } from '@/lib/demoMode'
import { QUICK_ASKS } from '@/lib/quickAsks'

const WELCOME_MSG = {
  id: 1,
  role: 'assistant',
  content: "Namaste! 🙏 I'm FarmAI — your agricultural advisor powered by AI.\n\nI can help you with:\n• Crop planning and variety selection\n• Pest and disease diagnosis\n• Market prices and selling timing\n• Irrigation scheduling\n• Government scheme eligibility\n\nWhat would you like to know today?",
  agent: 'supervisor',
  timestamp: new Date().toISOString(),
}

const DEFAULT_LANGUAGE = 'hi'

export default function ChatScreen() {
  const [messages, setMessages] = useState([WELCOME_MSG])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const { farmerId } = useFarmerProfile()
  const { isSupported, isRecording, audioBlob, startRecording, stopRecording, reset } = useVoice()
  const { addToQueue, queueSize } = useOfflineQueue(farmerId)

  useEffect(() => {
    if (!audioBlob) return
    handleVoiceSend(audioBlob)
    reset()
  }, [audioBlob]) // eslint-disable-line react-hooks/exhaustive-deps

  const addUserMessage = (content) => {
    const msg = { id: Date.now(), role: 'user', content, timestamp: new Date().toISOString() }
    setMessages((prev) => [...prev, msg])
    return msg
  }

  const addAssistantMessage = ({ text_response, translated_response, audio_url, agent_used }) => {
    setMessages((prev) => [
      ...prev,
      {
        id: Date.now() + 1,
        role: 'assistant',
        content: translated_response || text_response,
        agent: agent_used,
        audioUrl: audio_url,
        timestamp: new Date().toISOString(),
      },
    ])
  }

  const handleTextSend = async (text) => {
    const message = text || input.trim()
    if (!message) return
    setInput('')
    addUserMessage(message)
    setLoading(true)
    try {
      const data = await sendText(farmerId, message, DEFAULT_LANGUAGE)
      addAssistantMessage(data)
    } catch {
      if (!navigator.onLine) {
        await addToQueue({ text: message, language: DEFAULT_LANGUAGE })
        setMessages((prev) => [
          ...prev,
          {
            id: Date.now() + 1,
            role: 'assistant',
            content: "No internet connection. Your message has been queued and will be sent when you're back online.",
            agent: 'supervisor',
            timestamp: new Date().toISOString(),
          },
        ])
      } else {
        const demo = getDemoResponse(message)
        addAssistantMessage({ text_response: demo.text, agent_used: demo.agent })
      }
    } finally {
      setLoading(false)
    }
  }

  const handleVoiceSend = async (blob) => {
    if (!navigator.onLine) {
      setMessages((prev) => [
        ...prev,
        {
          id: Date.now(),
          role: 'assistant',
          content: 'No internet connection. Voice messages require a connection — please try again when online.',
          agent: 'supervisor',
          timestamp: new Date().toISOString(),
        },
      ])
      return
    }
    addUserMessage('🎤 Voice message')
    setLoading(true)
    try {
      const data = await sendVoice(farmerId, blob)
      addAssistantMessage(data)
    } catch {
      const demo = getDemoResponse('')
      addAssistantMessage({ text_response: demo.text, agent_used: demo.agent })
    } finally {
      setLoading(false)
    }
  }

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleTextSend()
    }
  }

  return (
    <div className="flex-1 max-w-4xl mx-auto w-full px-4 py-4 flex flex-col">
      <MessageList messages={messages} loading={loading} />

      {messages.length <= 2 && (
        <div className="py-2">
          <p className="text-xs text-gray-500 mb-2 text-center">Try asking:</p>
          <div className="flex flex-wrap gap-2 justify-center">
            {QUICK_ASKS.map((q, i) => (
              <button
                key={i}
                onClick={() => handleTextSend(q.text)}
                className="text-xs bg-white border border-green-200 text-green-700 rounded-full px-3 py-1.5 hover:bg-green-50 transition-colors shadow-sm"
              >
                {q.icon} {q.text}
              </button>
            ))}
          </div>
        </div>
      )}

      {queueSize > 0 && (
        <p className="text-xs text-amber-600 text-center mb-1">
          ⏳ {queueSize} message{queueSize > 1 ? 's' : ''} queued — will send when online
        </p>
      )}

      <div className="py-3">
        <div className="flex gap-2 bg-white rounded-2xl shadow-sm border border-gray-200 p-2">
          <VoiceInput
            isSupported={isSupported}
            isRecording={isRecording}
            onStart={startRecording}
            onStop={stopRecording}
          />
          <textarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Ask about crops, pests, prices, or schemes..."
            className="flex-1 resize-none border-none outline-none text-sm text-gray-700 px-2 pt-1"
            rows={1}
            style={{ minHeight: '36px', maxHeight: '120px' }}
          />
          <button
            onClick={() => handleTextSend()}
            disabled={loading || !input.trim()}
            aria-label="Send"
            className="bg-green-600 text-white rounded-xl px-4 py-2 text-sm font-medium disabled:opacity-40 hover:bg-green-700 transition-colors flex-shrink-0"
          >
            {loading ? '...' : 'Send'}
          </button>
        </div>
        <p className="text-xs text-gray-400 text-center mt-1">
          Multi-agent AI • MCP tools • RAG knowledge base
        </p>
      </div>
    </div>
  )
}
