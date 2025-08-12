class ConversationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  # List all conversations for current user (most recent first)
  def index
    @conversations = Conversation
                       .joins(:conversation_participants)
                       .where(conversation_participants: { user_id: current_user.id })
                       .includes(:users)
                       .order(updated_at: :desc)

    respond_to do |f|
      f.json do
        render json: @conversations.as_json(
          only: %i[id title group updated_at],
          include: { users: { only: %i[id email username name avatar_url] } }
        )
      end
      f.html # views/conversations/index.html.erb (optional)
    end
  end

  # Show a conversation and last 50 messages (ascending time)
  def show
    @conversation = find_conversation!
    @messages = @conversation.messages.order(created_at: :asc).last(50)

    respond_to do |f|
      f.json do
        render json: {
          conversation: @conversation.slice(:id, :title, :group, :updated_at),
          participants: @conversation.users.select(:id, :email, :username, :name, :avatar_url),
          messages: @messages.as_json(only: %i[id user_id body created_at])
        }
      end
      f.html # views/conversations/show.html.erb (optional)
    end
  end

  # Create 1-1 or group conversation
  # params: { participant_ids: [2,3,...], title? }
  def create
    participant_ids = Array(params[:participant_ids]).map(&:to_i).uniq
    if participant_ids.empty?
      return render json: { error: "participant_ids required" }, status: :unprocessable_entity
    end

    # always include current_user
    all_ids = (participant_ids + [current_user.id]).uniq
    is_group = all_ids.size >= 3

    if is_group && all_ids.size < 3
      return render json: { error: "Group chats require 3+ participants" }, status: :unprocessable_entity
    end

    title = is_group ? (params[:title].presence || "Group Chat") : nil

    conversation = nil
    ActiveRecord::Base.transaction do
      # Optional: prevent duplicate 1-1 conversation between same two users
      if !is_group && (existing = find_direct_conversation_with(all_ids))
        conversation = existing
      else
        conversation = Conversation.create!(title: title, group: is_group)
        all_ids.each { |uid| ConversationParticipant.create!(conversation:, user_id: uid) }
      end
    end

    render json: { id: conversation.id }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def find_conversation!
    Conversation
      .joins(:conversation_participants)
      .find_by!(id: params[:id], conversation_participants: { user_id: current_user.id })
  end

  # returns an existing 1-1 conversation with exactly the two users, else nil
  def find_direct_conversation_with(user_ids)
    return nil unless user_ids.size == 2
    Conversation
      .joins(:conversation_participants)
      .where(group: false)
      .where(conversation_participants: { user_id: user_ids })
      .group("conversations.id")
      .having("COUNT(conversation_participants.id) = 2")
      .first
  end
end
