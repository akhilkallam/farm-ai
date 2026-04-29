import { render, screen } from '@testing-library/react'
import AgentStatus from '@/components/dashboard/AgentStatus'

test('renders Agent System Status heading', () => {
  render(<AgentStatus />)
  expect(screen.getByText(/Agent System Status/i)).toBeInTheDocument()
})

test('renders all 5 specialist agents', () => {
  render(<AgentStatus />)
  expect(screen.getByText(/crop advisor/i)).toBeInTheDocument()
  expect(screen.getByText(/pest detector/i)).toBeInTheDocument()
  expect(screen.getByText(/market analyst/i)).toBeInTheDocument()
  expect(screen.getByText(/irrigation planner/i)).toBeInTheDocument()
  expect(screen.getByText(/scheme navigator/i)).toBeInTheDocument()
})

test('renders MCP Tools section', () => {
  render(<AgentStatus />)
  expect(screen.getByText(/MCP Tools Active/i)).toBeInTheDocument()
  expect(screen.getByText(/weather_forecast/i)).toBeInTheDocument()
})
