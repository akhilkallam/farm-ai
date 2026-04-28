'use client'
import { useState, useEffect } from 'react'

export default function ThinkingBubble() {
  const [dots, setDots] = useState('.')
  useEffect(() => {
    const id = setInterval(() => setDots((d) => (d.length >= 3 ? '.' : d + '.')), 500)
    return () => clearInterval(id)
  }, [])

  return (
    <div className="flex justify-start mb-4">
      <div className="w-8 h-8 rounded-full bg-green-500 flex items-center justify-center text-white text-sm mr-2 flex-shrink-0">
        🌱
      </div>
      <div className="bg-white border border-gray-100 shadow-sm px-4 py-3 rounded-2xl rounded-tl-sm">
        <div className="flex items-center gap-2">
          <div className="flex gap-1">
            {[0, 1, 2].map((i) => (
              <div
                key={i}
                className="w-2 h-2 bg-green-400 rounded-full animate-bounce"
                style={{ animationDelay: `${i * 0.15}s` }}
              />
            ))}
          </div>
          <span className="text-xs text-gray-500">Agents working{dots}</span>
        </div>
      </div>
    </div>
  )
}
