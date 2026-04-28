import { renderHook, act } from '@testing-library/react'
import { useFarmerProfile } from '@/hooks/useFarmerProfile'

beforeEach(() => {
  localStorage.clear()
})

test('returns "demo-farmer" when no stored value', () => {
  const { result } = renderHook(() => useFarmerProfile())
  expect(result.current.farmerId).toBe('demo-farmer')
})

test('returns stored farmer_id from localStorage', () => {
  localStorage.setItem('farm-ai-farmer-id', 'raju-reddy')
  const { result } = renderHook(() => useFarmerProfile())
  expect(result.current.farmerId).toBe('raju-reddy')
})

test('setFarmerId updates value and persists to localStorage', () => {
  const { result } = renderHook(() => useFarmerProfile())
  act(() => {
    result.current.setFarmerId('balwinder-singh')
  })
  expect(result.current.farmerId).toBe('balwinder-singh')
  expect(localStorage.getItem('farm-ai-farmer-id')).toBe('balwinder-singh')
})
