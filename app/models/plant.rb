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
      .where.not("image_url LIKE ?", "%#{LOCKED_IMAGE}%")
  }

  DETAILS_TTL = 7.days
  # Perenual's image for species outside the API plan (on the free plan, ids above 3000)
  LOCKED_IMAGE = "upgrade_access".freeze

  def self.locked_image?(url)
    url.to_s.include?(LOCKED_IMAGE)
  end

  # Perenual's image links are signed and stop working after X-Amz-Expires seconds
  def self.expired_link?(url, margin: 1.hour)
    query = Rack::Utils.parse_query(URI(url.to_s).query.to_s)
    return false if query["X-Amz-Date"].blank? || query["X-Amz-Expires"].blank?

    Time.parse(query["X-Amz-Date"]) + query["X-Amz-Expires"].to_i.seconds < margin.from_now
  rescue ArgumentError, URI::InvalidURIError
    false
  end

  def display_name
    name.to_s.titleize
  end

  def locked?
    self.class.locked_image?(image_url) || self.class.locked_image?(api_image_url)
  end

  def needs_details?
    return false if perenual_id.blank? || locked?

    description.blank? || synced_at.blank? || synced_at <= DETAILS_TTL.ago || image_expired?
  end

  def image_expired?
    stored_image_url.blank? && self.class.expired_link?(api_image_url.presence || image_url)
  end

  def displayable?
    image_url.present? && care_content?
  end

  def care_content?
    description.present? || plant_info.present?
  end
end
