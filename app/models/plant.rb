class Plant < ApplicationRecord
  has_many :favorites, dependent: :destroy
  has_many :chats, dependent: :destroy
  validates :name, presence: true, uniqueness: true
  validates :image_url, presence: true

  validates :light_needs, inclusion: { in: ["low", "medium", "bright indirect", "direct sun"] }
  validates :water_needs, inclusion: { in: ["low", "moderate", "high"] }
  validates :care_level, inclusion: { in: ["easy", "medium", "advanced"] }
  validates :indoor_outdoor, inclusion: { in: ["indoor", "outdoor", "both"] }

  def display_name
    name.to_s.titleize
  end
end
