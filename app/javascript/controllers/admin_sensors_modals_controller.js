import { Controller } from '@hotwired/stimulus'
import { loadI18n } from 'sensor_setup/i18n'

// Shared QR + destroy modals: load HTML on demand, then open the native <dialog>.
export default class extends Controller {
  static targets = ['qrBody', 'destroyBody']

  connect () {
    this.qrDialog = document.getElementById('admin-shared-qr-sticker')
    this.destroyDialog = document.getElementById('admin-shared-destroy-sensor')
  }

  async i18n () {
    if (!this._i18n) this._i18n = await loadI18n()
    return this._i18n
  }

  async openQr (event) {
    const url = event.currentTarget?.dataset?.qrStickerUrl
    if (!url || !this.hasQrBodyTarget) return
    this.abortController?.abort()
    this.abortController = new AbortController()
    this.qrBodyTarget.innerHTML = await this.loadingBlock()
    const ok = await this.loadFragment(
      url,
      this.qrBodyTarget,
      'admin-shared-qr-sticker',
      this.abortController.signal
    )
    if (ok) this.qrDialog?.showModal()
  }

  async openDestroy (event) {
    const url = event.currentTarget?.dataset?.destroyConfirmUrl
    if (!url || !this.hasDestroyBodyTarget) return
    this.abortController?.abort()
    this.abortController = new AbortController()
    this.destroyBodyTarget.innerHTML = await this.loadingBlock()
    const ok = await this.loadFragment(
      url,
      this.destroyBodyTarget,
      'admin-shared-destroy-sensor',
      this.abortController.signal
    )
    if (ok) this.destroyDialog?.showModal()
  }

  async loadFragment (url, target, dialogId, signal) {
    const headers = {
      Accept: 'text/html',
      'X-Requested-With': 'XMLHttpRequest',
      'X-CSRF-Token': this.csrfToken()
    }

    try {
      const res = await fetch(url, { headers, credentials: 'same-origin', signal })
      if (!res.ok) throw new Error('bad')
      const html = await res.text()
      target.innerHTML = html
      return true
    } catch (e) {
      if (e.name === 'AbortError') return false
      target.innerHTML = await this.errorBlock(dialogId)
      document.getElementById(dialogId)?.showModal()
      return false
    }
  }

  async errorBlock (dialogId) {
    const i18n = await this.i18n()
    const text = i18n.t('admin.sensors.index.modal_load_error')
    return (
      '<div class="p-6 text-center">' +
        `<p class="text-sm text-rose-600 font-palanquin mb-4">${this.escape(text)}</p>` +
        `<button type="button" command="close" commandfor="${dialogId}" class="text-[10px] font-bold text-pulse-moss/50 uppercase tracking-[0.15em]">` +
        'OK</button></div>'
    )
  }

  async loadingBlock () {
    const i18n = await this.i18n()
    const text = i18n.t('admin.sensors.index.modal_loading')
    return (
      '<div class="p-8 flex items-center justify-center min-h-[12rem]">' +
        `<p class="text-[10px] text-pulse-moss/50 font-palanquin tracking-widest uppercase">${this.escape(text)}</p>` +
      '</div>'
    )
  }

  escape (s) {
    return s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
  }

  csrfToken () {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
  }
}
