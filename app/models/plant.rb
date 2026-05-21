class Plant < ApplicationRecord
  has_many :favorites, dependent: :destroy
  has_many :chats, dependent: :destroy
  validates :name, presence: true, uniqueness: true
  validates :image_url, presence: true

  validates :light_needs, inclusion: { in: ["low", "medium", "bright indirect", "direct sun"] }
  validates :water_needs, inclusion: { in: ["low", "moderate", "high"] }
  validates :care_level, inclusion: { in: ["easy", "medium", "advanced"] }
  validates :indoor_outdoor, inclusion: { in: ["indoor", "outdoor", "both"] }

  scope :displayable, lambda {
    where("NULLIF(TRIM(image_url), '') IS NOT NULL")
      .where("NULLIF(TRIM(description), '') IS NOT NULL OR NULLIF(TRIM(plant_info), '') IS NOT NULL")
  }

  def display_name
    name.to_s.titleize
  end

  def displayable?
    image_url.present? && care_content?
  end

  def care_content?
    description.present? || plant_info.present?
  end
end
