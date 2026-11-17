require "test_helper"

class PlantTest < ActiveSupport::TestCase
  test "displayable plants have an image and care content" do
    plant = Plant.new(image_url: "https://example.com/plant.jpg", description: "Care notes")

    assert plant.displayable?
  end

  test "plants without an image are not displayable" do
    plant = Plant.new(description: "Care notes")

    assert_not plant.displayable?
  end

  test "plants without care content are not displayable" do
    plant = Plant.new(image_url: "https://example.com/plant.jpg")

    assert_not plant.displayable?
  end

  test "displayable scope filters plants without care content" do
    displayable = Plant.create!(
      name: "Displayable Fern",
      light_needs: "low",
      water_needs: "moderate",
      care_level: "easy",
      indoor_outdoor: "indoor",
      image_url: "https://example.com/displayable-fern.jpg",
      description: "Care notes"
    )
    Plant.create!(
      name: "Empty Fern",
      light_needs: "low",
      water_needs: "moderate",
      care_level: "easy",
      indoor_outdoor: "indoor",
      image_url: "https://example.com/empty-fern.jpg"
    )

    assert_equal [displayable], Plant.displayable.to_a
  end

  test "signed Perenual image links expire" do
    link = lambda do |signed_at|
      "https://s3.example.com/plant.jpg?X-Amz-Date=#{signed_at.utc.strftime('%Y%m%dT%H%M%SZ')}&X-Amz-Expires=86400"
    end

    assert Plant.expired_link?(link.call(25.hours.ago))
    assert Plant.expired_link?(link.call(23.5.hours.ago)), "under an hour left counts as expired"
    assert_not Plant.expired_link?(link.call(1.hour.ago))
    assert_not Plant.expired_link?("https://res.cloudinary.com/demo/image/upload/plant.jpg")
  end

  test "a plant with a stored photo copy no longer needs fresh links" do
    expired = "https://s3.example.com/plant.jpg?X-Amz-Date=20200101T000000Z&X-Amz-Expires=86400"
    plant = Plant.new(perenual_id: 1, description: "Care notes", synced_at: Time.current, image_url: expired)

    assert plant.needs_details?

    plant.stored_image_url = "https://res.cloudinary.com/demo/image/upload/plant.jpg"
    assert_not plant.needs_details?
  end

  test "displayable scope treats whitespace content as empty" do
    Plant.create!(
      name: "Whitespace Fern",
      light_needs: "low",
      water_needs: "moderate",
      care_level: "easy",
      indoor_outdoor: "indoor",
      image_url: "https://example.com/whitespace-fern.jpg",
      description: "  "
    )

    assert_empty Plant.displayable.to_a
  end
end
