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
