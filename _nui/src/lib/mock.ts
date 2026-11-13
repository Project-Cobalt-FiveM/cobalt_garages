import { installMock, type MessageAction } from './nui'
import { creatorHandlers, creatorPayload, placementPayload } from './mock-creator'
import { garageHandlers, garagePayload, impoundPayload } from './mock-garage'

function post(action: MessageAction, data?: unknown) {
  window.postMessage({ action, data }, '*')
}

installMock({
  ...garageHandlers(post),
  ...creatorHandlers(post),
  close: () => true,
})

document.documentElement.style.background = '#3F3F46'

const view = new URLSearchParams(window.location.search).get('view') ?? 'garage'

setTimeout(() => {
  if (view === 'garage') post('open', { view: 'garage', payload: garagePayload() })
  if (view === 'impound') post('open', { view: 'garage', payload: impoundPayload() })
  if (view === 'creator') post('open', { view: 'creator', payload: creatorPayload() })
  if (view === 'placement') {
    post('open', { view: 'creator', payload: creatorPayload() })
    post('placement', placementPayload())
  }
}, 50)
