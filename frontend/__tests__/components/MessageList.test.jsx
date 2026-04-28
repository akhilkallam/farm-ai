import { render, screen } from '@testing-library/react'
import MessageList from '@/components/chat/MessageList'

const messages = [
  { id: 1, role: 'assistant', content: 'Hello farmer', agent: 'supervisor', timestamp: new Date().toISOString() },
  { id: 2, role: 'user', content: 'Hello FarmAI', timestamp: new Date().toISOString() },
]

test('renders all messages', () => {
  render(<MessageList messages={messages} loading={false} />)
  expect(screen.getByText('Hello farmer')).toBeInTheDocument()
  expect(screen.getByText('Hello FarmAI')).toBeInTheDocument()
})

test('shows ThinkingBubble when loading is true', () => {
  render(<MessageList messages={messages} loading={true} />)
  expect(screen.getByText(/Agents working/i)).toBeInTheDocument()
})

test('does not show ThinkingBubble when loading is false', () => {
  render(<MessageList messages={messages} loading={false} />)
  expect(screen.queryByText(/Agents working/i)).not.toBeInTheDocument()
})
