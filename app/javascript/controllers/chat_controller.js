import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"
import { subscribeToConversation } from "channels/conversations_channel"

export default class extends Controller {
    static values = { conversationId: Number }

    connect() {
        this.subscription = subscribeToConversation(
            this.conversationIdValue,
            (message) => this.onIncomingMessage(message)
        )
    }

    disconnect() {
        this.subscription?.unsubscribe()
    }

    onIncomingMessage(msg) {
        const me = document.querySelector('meta[name="current-user-id"]')?.content
        const mine = me && String(msg.user_id) === String(me)
        const div = document.createElement("div")
        div.className = mine ? "text-right" : ""
        div.innerHTML = `
      <span class="inline-block px-3 py-1 rounded bg-gray-100"></span>
      <small class="text-gray-500">${new Date(msg.created_at).toLocaleTimeString()}</small>
    `
        div.querySelector("span").appendChild(document.createTextNode(msg.body))
        this.element.appendChild(div)
        this.element.scrollTop = this.element.scrollHeight
    }

    disconnect() {
        this.subscription?.unsubscribe()
        this.consumer?.disconnect()
    }

    received(payload) {
        const data = payload.message || payload.data || payload
        if (!data) return
        const me = document.querySelector('meta[name="current-user-id"]')?.content
        const mine = me && String(data.user_id) === String(me)

        const div = document.createElement("div")
        div.className = mine ? "text-right" : ""
        div.innerHTML = `
      <span class="inline-block px-3 py-1 rounded bg-gray-100"></span>
      <small class="text-gray-500">${new Date(data.created_at).toLocaleTimeString()}</small>
    `
        div.querySelector("span").appendChild(document.createTextNode(data.body))
        this.element.appendChild(div)
        this.element.scrollTop = this.element.scrollHeight
    }

    async send(event) {
        event.preventDefault()
        const form = event.target
        const input = form.querySelector('input[name="body"]')
        const body = (input.value || "").trim()
        if (!body) return
        const resp = await fetch(form.action, {
            method: "POST",
            headers: { "X-CSRF-Token": form.querySelector('input[name="authenticity_token"]').value,
                "Content-Type": "application/json" },
            body: JSON.stringify({ body })
        })
        if (resp.ok) { input.value = "" } else { alert("Failed to send") }
    }
}
