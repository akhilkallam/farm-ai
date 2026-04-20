import '@testing-library/jest-dom'

// Polyfills for Node.js test environment
if (typeof global.Request === 'undefined') {
  global.Request = class Request {
    constructor(url, options = {}) {
      this.url = url
      this.method = options.method || 'GET'
      this.headers = options.headers || {}
      this.body = options.body
    }
    async json() {
      return JSON.parse(this.body)
    }
    async formData() {
      return this.body
    }
  }
}

if (typeof global.Response === 'undefined') {
  global.Response = class Response {
    constructor(body, options = {}) {
      this.body = body
      this.status = options.status || 200
      this.statusText = options.statusText || 'OK'
    }
    async json() {
      return typeof this.body === 'string' ? JSON.parse(this.body) : this.body
    }
    static json(data, options = {}) {
      return new Response(JSON.stringify(data), { status: options.status || 200 })
    }
  }
}

if (typeof global.FormData === 'undefined') {
  global.FormData = class FormData {
    constructor() {
      this.entries = []
    }
    append(key, value, filename) {
      this.entries.push({ key, value, filename })
    }
  }
}

if (typeof global.Blob === 'undefined') {
  global.Blob = class Blob {
    constructor(parts = [], options = {}) {
      this.data = parts.join('')
      this.type = options.type || ''
    }
  }
}
