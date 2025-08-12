# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  before_action :load_conversation!

  # GET /conversations/:conversation_id/messages
  # Query params:
  #   before=ISO8601  -> fetch messages created strictly before this timestamp
  #   after=ISO8601   -> fetch messages created strictly after this timestamp
  #   limit=integer   -> max 200; default 50
  #
  # Behavior:
  # - If both before & after are provided, 'after' wins (cursor forward).
  # - Returns messages ASC by created_at.
  def index
    scope = @conversation.messages

    # Parse cursors safely
    before_time = parse_time(params[:before])
    after_time  = parse_time(params[:after])

    if after_time
      scope = scope.where("created_at > ?", after_time).order(created_at: :asc)
    else
      scope = scope.where("created_at < ?", before_time) if before_time
      scope = scope.order(created_at: :desc)
    end

    limit = safe_limit(params[:limit])
    records = scope.limit(limit)

    # If we used DESC (before cursor), flip to ASC for UI friendliness
    records = records.reorder(created_at: :asc) unless after_time

    render json: {
      messages: records.as_json(only: %i[id user_id body created_at]),
      page_info: {
        count: records.size,
        oldest: records.first&.created_at,
        newest: records.last&.created_at,
        cursor: {
          before: records.first&.created_at&.iso8601,
          after:  records.last&.created_at&.iso8601
        }
      }
    }
  end

  def create
    message = @conversation.messages.build(message_params.merge(user: current_user))

    if message.save
      ConversationsChannel.broadcast_to(
        @conversation,
        message: message.as_json(only: %i[id user_id body created_at])
      )

      render json: message, status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def load_conversation!
    @conversation = Conversation
                      .joins(:conversation_participants)
                      .find_by!(id: params[:conversation_id], conversation_participants: { user_id: current_user.id })
  end

  def parse_time(val)
    return nil if val.blank?
    Time.zone.parse(val)
  rescue ArgumentError, TypeError
    nil
  end

  def safe_limit(val)
    n = val.to_i
    n = 50 if n <= 0
    [n, 200].min
  end
end
