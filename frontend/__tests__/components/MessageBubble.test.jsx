import { render, screen } from '@testing-library/react'
import MessageBubble from '@/components/chat/MessageBubble'

const userMsg = {
  id: 1,
  role: 'user',
  content: 'Which crop for Rabi season?',
  timestamp: new Date('2026-01-01T10:00:00').toISOString(),
}

const assistantMsg = {
  id: 2,
  role: 'assistant',
  content: 'Plant wheat for Rabi season.',
  agent: 'crop_advisor',
  timestamp: new Date('2026-01-01T10:00:05').toISOString(),
}

const voiceAssistantMsg = {
  ...assistantMsg,
  audioUrl: 'http://localhost:8002/audio/test.mp3',
}

test('renders user message text', () => {
  render(<MessageBubble msg={userMsg} />)
  expect(screen.getByText('Which crop for Rabi season?')).toBeInTheDocument()
})

test('user message is right-aligned', () => {
  const { container } = render(<MessageBubble msg={userMsg} />)
  const wrapper = container.firstChild
  expect(wrapper.className).toMatch(/justify-end/)
})

test('assistant message is left-aligned', () => {
  const { container } = render(<MessageBubble msg={assistantMsg} />)
  const wrapper = container.firstChild
  expect(wrapper.className).toMatch(/justify-start/)
})

test('assistant message shows agent badge', () => {
  render(<MessageBubble msg={assistantMsg} />)
  expect(screen.getByText(/crop advisor/i)).toBeInTheDocument()
})

test('shows audio player when audioUrl is present', () => {
  render(<MessageBubble msg={voiceAssistantMsg} />)
  expect(document.querySelector('audio')).toBeInTheDocument()
})

test('does not show audio player when no audioUrl', () => {
  render(<MessageBubble msg={assistantMsg} />)
  expect(document.querySelector('audio')).not.toBeInTheDocument()
})
