import consumer from "./consumer"

export function subscribeToConversation(conversationId, onMessageReceived) {
    return consumer.subscriptions.create(
        { channel: "ConversationsChannel", conversation_id: conversationId },
        {
            connected() {
                console.log(`Connected to conversation ${conversationId}`)
            },
            disconnected() {
                console.log(`Disconnected from conversation ${conversationId}`)
            },
            received(data) {
                if (data.message) {
                    onMessageReceived(data.message)
                }
            }
        }
    )
}
