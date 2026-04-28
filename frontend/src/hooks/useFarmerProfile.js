'use client'
import { useState, useEffect } from 'react'

const STORAGE_KEY = 'farm-ai-farmer-id'
const DEFAULT_FARMER_ID = 'demo-farmer'

export function useFarmerProfile() {
  const [farmerId, setFarmerIdState] = useState(DEFAULT_FARMER_ID)

  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY)
    if (stored) setFarmerIdState(stored)
  }, [])

  const setFarmerId = (id) => {
    setFarmerIdState(id)
    localStorage.setItem(STORAGE_KEY, id)
  }

  return { farmerId, setFarmerId }
}
