class Message < ApplicationRecord
  belongs_to :chat

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  validates :role, presence: true
  validates :content, presence: true
end
