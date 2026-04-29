import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import ChatScreen from '@/components/chat/ChatScreen'

// Mock all hooks and lib
jest.mock('@/hooks/useFarmerProfile', () => ({
  useFarmerProfile: () => ({ farmerId: 'demo-farmer', setFarmerId: jest.fn() }),
}))
jest.mock('@/hooks/useVoice', () => ({
  useVoice: () => ({
    isSupported: false,
    isRecording: false,
    audioBlob: null,
    startRecording: jest.fn(),
    stopRecording: jest.fn(),
    reset: jest.fn(),
  }),
}))
jest.mock('@/hooks/useOfflineQueue', () => ({
  useOfflineQueue: () => ({ addToQueue: jest.fn(), flushQueue: jest.fn(), queueSize: 0 }),
}))
jest.mock('@/lib/api', () => ({
  sendText: jest.fn(),
  sendVoice: jest.fn(),
}))
jest.mock('@/lib/demoMode', () => ({
  getDemoResponse: jest.fn(() => ({ text: 'Demo response', agent: 'crop_advisor' })),
}))

import { sendText } from '@/lib/api'
import { getDemoResponse } from '@/lib/demoMode'

beforeEach(() => jest.clearAllMocks())

test('renders initial welcome message', () => {
  render(<ChatScreen />)
  expect(screen.getByText(/Namaste/i)).toBeInTheDocument()
})

test('shows quick-ask buttons when few messages', () => {
  render(<ChatScreen />)
  expect(screen.getByText(/Which crop for Rabi season/i)).toBeInTheDocument()
})

test('sends message on Send button click', async () => {
  sendText.mockResolvedValue({ text_response: 'Plant wheat', translated_response: 'Plant wheat', agent_used: 'crop_advisor', queued: false })

  render(<ChatScreen />)
  const textarea = screen.getByPlaceholderText(/Ask about crops/i)
  fireEvent.change(textarea, { target: { value: 'What to plant?' } })
  fireEvent.click(screen.getByRole('button', { name: /send/i }))

  await waitFor(() => {
    expect(sendText).toHaveBeenCalledWith('demo-farmer', 'What to plant?', 'hi')
  })
})

test('falls back to demo mode when API throws', async () => {
  sendText.mockRejectedValue(new Error('Network error'))

  render(<ChatScreen />)
  const textarea = screen.getByPlaceholderText(/Ask about crops/i)
  fireEvent.change(textarea, { target: { value: 'crop question' } })
  fireEvent.click(screen.getByRole('button', { name: /send/i }))

  await waitFor(() => {
    expect(getDemoResponse).toHaveBeenCalledWith('crop question')
  })
})

test('Send button is disabled when input is empty', () => {
  render(<ChatScreen />)
  expect(screen.getByRole('button', { name: /send/i })).toBeDisabled()
})
