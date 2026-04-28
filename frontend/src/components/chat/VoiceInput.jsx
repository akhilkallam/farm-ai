'use client'

export default function VoiceInput({ isSupported, isRecording, onStart, onStop }) {
  return (
    <button
      onMouseDown={onStart}
      onMouseUp={onStop}
      onTouchStart={(e) => { e.preventDefault(); onStart() }}
      onTouchEnd={(e) => { e.preventDefault(); onStop() }}
      disabled={!isSupported}
      aria-label={isRecording ? 'Recording...' : 'Hold to record'}
      className={`flex flex-col items-center justify-center w-12 h-12 rounded-full transition-all flex-shrink-0 ${
        !isSupported
          ? 'bg-gray-200 text-gray-400 cursor-not-allowed opacity-50'
          : isRecording
          ? 'bg-red-500 text-white shadow-lg scale-110 animate-pulse'
          : 'bg-green-100 text-green-700 hover:bg-green-200'
      }`}
    >
      <span className="text-xl">{isRecording ? '⏺' : '🎤'}</span>
      <span className="text-[9px] leading-none mt-0.5">
        {isRecording ? 'Recording...' : 'Hold to record'}
      </span>
    </button>
  )
}
