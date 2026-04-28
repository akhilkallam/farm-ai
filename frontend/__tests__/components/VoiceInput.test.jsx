import { render, screen, fireEvent } from '@testing-library/react'
import VoiceInput from '@/components/chat/VoiceInput'

test('renders mic button', () => {
  render(<VoiceInput isSupported={true} isRecording={false} onStart={jest.fn()} onStop={jest.fn()} />)
  expect(screen.getByRole('button', { name: /hold to record|recording/i })).toBeInTheDocument()
})

test('button is disabled when isSupported is false', () => {
  render(<VoiceInput isSupported={false} isRecording={false} onStart={jest.fn()} onStop={jest.fn()} />)
  expect(screen.getByRole('button')).toBeDisabled()
})

test('calls onStart on mousedown', () => {
  const onStart = jest.fn()
  render(<VoiceInput isSupported={true} isRecording={false} onStart={onStart} onStop={jest.fn()} />)
  fireEvent.mouseDown(screen.getByRole('button'))
  expect(onStart).toHaveBeenCalledTimes(1)
})

test('calls onStop on mouseup', () => {
  const onStop = jest.fn()
  render(<VoiceInput isSupported={true} isRecording={true} onStart={jest.fn()} onStop={onStop} />)
  fireEvent.mouseUp(screen.getByRole('button'))
  expect(onStop).toHaveBeenCalledTimes(1)
})

test('shows "Recording..." label when isRecording is true', () => {
  render(<VoiceInput isSupported={true} isRecording={true} onStart={jest.fn()} onStop={jest.fn()} />)
  expect(screen.getByText(/Recording\.\.\./i)).toBeInTheDocument()
})

test('shows mic label when not recording', () => {
  render(<VoiceInput isSupported={true} isRecording={false} onStart={jest.fn()} onStop={jest.fn()} />)
  expect(screen.getByText(/Hold to record/i)).toBeInTheDocument()
})
