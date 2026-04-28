'use client'
import { useState, useRef, useCallback } from 'react'

export function useVoice() {
  const isSupported = typeof window !== 'undefined' && 'MediaRecorder' in window
  const [isRecording, setIsRecording] = useState(false)
  const [audioBlob, setAudioBlob] = useState(null)
  const [error, setError] = useState(null)
  const recorderRef = useRef(null)
  const chunksRef = useRef([])
  const streamRef = useRef(null)

  const startRecording = useCallback(async () => {
    if (!isSupported) return
    try {
      setError(null)
      setAudioBlob(null)
      chunksRef.current = []
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      streamRef.current = stream
      const recorder = new MediaRecorder(stream)
      recorderRef.current = recorder
      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunksRef.current.push(e.data)
      }
      recorder.onstop = () => {
        const blob = new Blob(chunksRef.current, { type: 'audio/m4a' })
        setAudioBlob(blob)
        streamRef.current?.getTracks().forEach((t) => t.stop())
      }
      recorder.start()
      setIsRecording(true)
    } catch (err) {
      setError(err.message)
    }
  }, [isSupported])

  const stopRecording = useCallback(() => {
    if (recorderRef.current && isRecording) {
      recorderRef.current.stop()
      setIsRecording(false)
    }
  }, [isRecording])

  const reset = useCallback(() => {
    setAudioBlob(null)
    setError(null)
  }, [])

  return { isSupported, isRecording, audioBlob, error, startRecording, stopRecording, reset }
}
