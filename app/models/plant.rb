class Plant < ApplicationRecord
  has_many :favorites, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :image_url, presence: true

  validates :light_needs, inclusion: { in: ["low", "medium", "bright indirect", "direct sun"] }
  validates :growth_style, inclusion: { in: ["upright", "trailing", "climbing", "bushy", "compact"] }
  validates :water_needs, inclusion: { in: ["low", "moderate", "high"] }
  validates :care_level, inclusion: { in: ["easy", "medium", "advanced"] }
  validates :indoor_outdoor, inclusion: { in: ["indoor", "outdoor", "both"] }
end
