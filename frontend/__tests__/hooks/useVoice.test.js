import { renderHook, act } from '@testing-library/react'
import { useVoice } from '@/hooks/useVoice'

function buildMockMediaRecorder() {
  const instance = {
    start: jest.fn(),
    stop: jest.fn(),
    state: 'inactive',
    ondataavailable: null,
    onstop: null,
  }
  return instance
}

beforeEach(() => {
  global.MediaRecorder = jest.fn().mockImplementation(() => buildMockMediaRecorder())
  global.MediaRecorder.isTypeSupported = jest.fn().mockReturnValue(true)
  global.navigator.mediaDevices = {
    getUserMedia: jest.fn().mockResolvedValue({ getTracks: () => [{ stop: jest.fn() }] }),
  }
})

afterEach(() => {
  delete global.MediaRecorder
  delete global.navigator.mediaDevices
  jest.resetAllMocks()
})

test('isSupported is true when MediaRecorder is available', () => {
  const { result } = renderHook(() => useVoice())
  expect(result.current.isSupported).toBe(true)
})

test('isSupported is false when MediaRecorder is not available', () => {
  delete global.MediaRecorder
  const { result } = renderHook(() => useVoice())
  expect(result.current.isSupported).toBe(false)
})

test('isRecording starts as false', () => {
  const { result } = renderHook(() => useVoice())
  expect(result.current.isRecording).toBe(false)
})

test('startRecording requests microphone and starts MediaRecorder', async () => {
  const { result } = renderHook(() => useVoice())
  await act(async () => {
    await result.current.startRecording()
  })
  expect(navigator.mediaDevices.getUserMedia).toHaveBeenCalledWith({ audio: true })
  expect(result.current.isRecording).toBe(true)
})

test('stopRecording sets isRecording to false and calls recorder.stop()', async () => {
  const { result } = renderHook(() => useVoice())
  await act(async () => {
    await result.current.startRecording()
  })
  act(() => {
    result.current.stopRecording()
  })
  expect(result.current.isRecording).toBe(false)
})
