import './globals.css'

export const metadata = {
  title: 'FarmAI',
  description: 'AI Agricultural Advisor powered by Claude + MCP + RAG',
  manifest: '/manifest.json',
}

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
