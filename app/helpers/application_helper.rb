module ApplicationHelper
  def plant_image(plant, css_class:, image_url: nil)
    source = image_url.presence || plant.api_image_url.presence || plant.image_url.presence
    return plant_placeholder(css_class) if source.blank?

    image_tag source,
              class: css_class,
              alt: plant.display_name,
              loading: "lazy",
              onerror: "this.onerror=null;this.src='#{image_path("leaf.png")}';this.classList.add('plant-image-fallback');"
  end

  def plant_placeholder(css_class)
    classes = ["plant-placeholder"]
    classes << "detail-image" if css_class.to_s.include?("detail-image")

    content_tag(:div, "Plant", class: classes.join(" "))
  end
end
