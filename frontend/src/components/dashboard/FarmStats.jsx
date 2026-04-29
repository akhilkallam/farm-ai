'use client'

function StatCard({ icon, label, value, sub }) {
  return (
    <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
      <div className="flex items-center gap-3">
        <div className="text-2xl">{icon}</div>
        <div>
          <div className="text-xs text-gray-500">{label}</div>
          <div className="text-lg font-bold text-gray-800">{value}</div>
          {sub && <div className="text-xs text-green-600">{sub}</div>}
        </div>
      </div>
    </div>
  )
}

export default function FarmStats() {
  return (
    <div className="space-y-4">
      <h2 className="text-lg font-bold text-gray-700">Farm Overview</h2>
      <div className="grid grid-cols-2 gap-3">
        <StatCard icon="🌾" label="Current Crops" value="Cotton, Tomato" sub="Kharif season" />
        <StatCard icon="📍" label="Location" value="Warangal" sub="Telangana" />
        <StatCard icon="🏞️" label="Land" value="5.5 acres" sub="Small farmer" />
        <StatCard icon="💧" label="Irrigation" value="Drip system" sub="Installed" />
      </div>
    </div>
  )
}
