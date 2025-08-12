class Conversation < ApplicationRecord
  has_many :conversation_participants, dependent: :destroy
  has_many :users, through: :conversation_participants
  has_many :messages, dependent: :destroy
  validates :title, presence: true, if: :group?
  has_many :participants, through: :conversation_participants, source: :user
end
