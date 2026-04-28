import { render, screen } from '@testing-library/react'
import ThinkingBubble from '@/components/chat/ThinkingBubble'

test('renders three animated dots', () => {
  const { container } = render(<ThinkingBubble />)
  const dots = container.querySelectorAll('.animate-bounce')
  expect(dots.length).toBe(3)
})

test('renders "Agents working" text', () => {
  render(<ThinkingBubble />)
  expect(screen.getByText(/Agents working/i)).toBeInTheDocument()
})
