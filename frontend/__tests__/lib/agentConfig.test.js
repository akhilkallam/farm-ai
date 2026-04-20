import { AGENT_COLORS, AGENT_ICONS } from '@/lib/agentConfig'

const EXPECTED_AGENTS = ['crop_advisor', 'pest_detector', 'market_analyst', 'irrigation_planner', 'scheme_navigator', 'supervisor']

test('AGENT_COLORS has entry for every agent', () => {
  EXPECTED_AGENTS.forEach(agent => {
    expect(AGENT_COLORS).toHaveProperty(agent)
  })
})

test('AGENT_ICONS has entry for every agent', () => {
  EXPECTED_AGENTS.forEach(agent => {
    expect(AGENT_ICONS).toHaveProperty(agent)
  })
})

test('AGENT_COLORS values are Tailwind class strings', () => {
  Object.values(AGENT_COLORS).forEach(cls => {
    expect(typeof cls).toBe('string')
    expect(cls.length).toBeGreaterThan(0)
  })
})
