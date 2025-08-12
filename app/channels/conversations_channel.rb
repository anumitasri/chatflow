class ConversationsChannel < ApplicationCable::Channel
  def subscribed
    conversation = Conversation.find(params[:conversation_id])
    # Authorize subscription
    if conversation.users.include?(current_user)
      stream_for conversation
    else
      reject
    end
  end

  def unsubscribed
    # Cleanup if needed
  end
end
