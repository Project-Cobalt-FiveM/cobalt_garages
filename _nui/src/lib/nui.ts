declare global {
  interface Window {
    GetParentResourceName?: () => string
  }
}

export type CallbackName =
  | 'close'
  | 'garage:close'
  | 'garage:takeOut'
  | 'garage:takeFleet'
  | 'garage:release'
  | 'garage:store'
  | 'garage:transfer'
  | 'garage:transferTargets'
  | 'creator:check'
  | 'creator:clearance'
  | 'creator:delete'
  | 'creator:findCitizens'
  | 'creator:nearby'
  | 'creator:place'
  | 'creator:position'
  | 'creator:preview'
  | 'creator:save'
  | 'creator:teleport'

export type MessageAction = 'open' | 'garage' | 'placement' | 'close'

export type MockHandler = (data: Record<string, unknown>) => unknown

export const inGame = 'GetParentResourceName' in window

const resourceName = window.GetParentResourceName?.() ?? 'cobalt_garages'

let mockHandlers: Partial<Record<CallbackName, MockHandler>> | null = null

export function installMock(handlers: Partial<Record<CallbackName, MockHandler>>): void {
  mockHandlers = handlers
}

export async function nui(name: CallbackName, data: Record<string, unknown> = {}): Promise<unknown> {
  if (mockHandlers) {
    await new Promise((resolve) => setTimeout(resolve, 120))
    return mockHandlers[name]?.(data) ?? null
  }

  try {
    const response = await fetch(`https://${resourceName}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    })
    return await response.json()
  } catch {
    return null
  }
}

export function onNuiMessage(handler: (action: MessageAction, data: unknown) => void): () => void {
  const listener = (event: MessageEvent<unknown>) => {
    const message = event.data
    if (!isRecord(message)) return
    const action = message.action
    if (action === 'open' || action === 'garage' || action === 'placement' || action === 'close') handler(action, message.data)
  }
  window.addEventListener('message', listener)
  return () => window.removeEventListener('message', listener)
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

export function str(value: unknown): string | undefined {
  return typeof value === 'string' ? value : undefined
}

export function num(value: unknown): number | undefined {
  return typeof value === 'number' && Number.isFinite(value) ? value : undefined
}

export function list(value: unknown): unknown[] {
  if (Array.isArray(value)) return value
  if (isRecord(value)) return Object.values(value)
  return []
}
