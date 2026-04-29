import { render, screen } from '@testing-library/react'
import FarmStats from '@/components/dashboard/FarmStats'

test('renders Farm Overview heading', () => {
  render(<FarmStats />)
  expect(screen.getByText(/Farm Overview/i)).toBeInTheDocument()
})

test('renders all four stat cards', () => {
  render(<FarmStats />)
  expect(screen.getByText(/Current Crops/i)).toBeInTheDocument()
  expect(screen.getByText(/Location/i)).toBeInTheDocument()
  expect(screen.getByText(/Land/i)).toBeInTheDocument()
  expect(screen.getByText(/Irrigation/i)).toBeInTheDocument()
})
