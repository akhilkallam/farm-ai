export async function sendText(farmerId, text, language = 'hi') {
  const resp = await fetch('/api/text', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ farmer_id: farmerId, text, language }),
  })
  if (!resp.ok) throw new Error(String(resp.status))
  return resp.json()
}

export async function sendVoice(farmerId, audioBlob, languageHint = '') {
  const formData = new FormData()
  formData.append('farmer_id', farmerId)
  formData.append('audio', audioBlob, 'recording.m4a')
  if (languageHint) formData.append('language_hint', languageHint)

  const resp = await fetch('/api/voice', {
    method: 'POST',
    body: formData,
  })
  if (!resp.ok) throw new Error(String(resp.status))
  return resp.json()
}

export async function syncPull(farmerId) {
  const resp = await fetch(`/api/sync/pull/${farmerId}`)
  if (!resp.ok) throw new Error(String(resp.status))
  return resp.json()
}

export async function syncPush(requests) {
  const resp = await fetch('/api/sync/push', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ requests }),
  })
  if (!resp.ok) throw new Error(String(resp.status))
  return resp.json()
}
