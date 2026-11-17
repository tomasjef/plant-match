require "test_helper"

module Perenual
  class MatchPlantsTest < ActiveSupport::TestCase
    test "searches Perenual without fetching details and keeps plants that have an image" do
      client = FakePerenualClient.new

      plants = MatchPlants.new(params: match_params, client: client).call

      assert_equal ["Calathea Orbifolia"], plants.map(&:name)
      assert_nil plants.first.description
      assert_empty client.detail_ids
      assert_equal expected_search_params, client.species_list_params.first
    end

    test "plants from the search list take the answers Perenual matched on" do
      client = ListOnlyPerenualClient.new

      plant = MatchPlants.new(params: match_params.merge(light_needs: "low", water_needs: "low"), client: client).call.first

      assert_equal "low", plant.light_needs
      assert_equal "low", plant.water_needs
      assert_equal true, plant.pet_safe
    end

    test "pet safety stays unknown when the search did not filter on it" do
      client = ListOnlyPerenualClient.new

      plant = MatchPlants.new(params: match_params.merge(pet_safe: "false"), client: client).call.first

      assert_nil plant.pet_safe
      assert_nil client.species_list_params.first[:poisonous]
    end

    test "fetched details win over search answers" do
      Plant.create!(
        perenual_id: 98765,
        name: "Calathea Orbifolia",
        light_needs: "direct sun",
        water_needs: "high",
        care_level: "advanced",
        indoor_outdoor: "indoor",
        pet_safe: false,
        image_url: "https://example.com/calathea.jpg",
        description: "Details from Perenual."
      )

      plant = MatchPlants.new(params: match_params, client: ListOnlyPerenualClient.new).call.first

      assert_equal "direct sun", plant.light_needs
      assert_equal "high", plant.water_needs
      assert_equal false, plant.pet_safe
    end

    test "keeps matches that already have cached care content" do
      Plant.create!(
        perenual_id: 98765,
        name: "Cached Calathea",
        light_needs: "bright indirect",
        water_needs: "moderate",
        care_level: "medium",
        indoor_outdoor: "indoor",
        pet_safe: true,
        image_url: "https://example.com/cached-calathea.jpg",
        description: "A cached leafy indoor plant."
      )
      client = FakePerenualClient.new

      plants = MatchPlants.new(params: match_params, client: client).call

      assert_equal 1, plants.size
      assert_empty client.detail_ids
      assert_equal "Calathea Orbifolia", plants.first.name
      assert_equal "A cached leafy indoor plant.", plants.first.description
      assert_equal "medium", plants.first.care_level
      assert plants.first.pet_safe
      assert_equal expected_search_params, client.species_list_params.first
    end

    test "deduplicates Perenual candidates by scientific name" do
      Plant.create!(
        perenual_id: 98765,
        name: "Cached Calathea",
        scientific_name: "Goeppertia orbifolia",
        light_needs: "bright indirect",
        water_needs: "moderate",
        care_level: "medium",
        indoor_outdoor: "indoor",
        pet_safe: true,
        image_url: "https://example.com/cached-calathea.jpg",
        description: "A cached leafy indoor plant."
      )
      client = DuplicatePerenualClient.new

      plants = MatchPlants.new(params: match_params, client: client).call

      assert_equal 1, plants.size
      assert_equal [98765], plants.map(&:perenual_id)
    end

    test "asks for the second page only when the first has too few plants" do
      few = PagedPerenualClient.new(per_page: 3)
      MatchPlants.new(params: match_params, client: few).call
      assert_equal [1, 2], few.species_list_params.map { |params| params[:page] }

      enough = PagedPerenualClient.new(per_page: 12)
      MatchPlants.new(params: match_params, client: enough).call
      assert_equal [1], enough.species_list_params.map { |params| params[:page] }
    end

    test "repeats of a search come from the cache without asking Perenual" do
      with_memory_cache do
        MatchPlants.new(params: match_params, client: FakePerenualClient.new).call
        repeat = FakePerenualClient.new

        plants = MatchPlants.new(params: match_params, client: repeat).call

        assert_equal ["Calathea Orbifolia"], plants.map(&:name)
        assert_empty repeat.species_list_params
      end
    end

    private

    def with_memory_cache
      original = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      yield
    ensure
      Rails.cache = original
    end

    def match_params
      {
        light_needs: "bright indirect",
        water_needs: "moderate",
        care_level: "medium",
        pet_safe: "true"
      }
    end

    def expected_search_params
      {
        indoor: 1,
        watering: "average",
        sunlight: "part_shade",
        poisonous: 0,
        page: 1
      }
    end

    class FakePerenualClient
      attr_reader :detail_ids, :species_list_params

      def initialize
        @detail_ids = []
        @species_list_params = []
      end

      def species_list(params = {})
        species_list_params << params

        {
          "data" => [plant_without_image, plant_with_image],
          "last_page" => 1
        }
      end

      def species_details(id)
        detail_ids << id
        plant_details
      end

      private

      def plant_without_image
        {
          "id" => 98764,
          "common_name" => "Image Missing Plant"
        }
      end

      def plant_with_image
        {
          "id" => 98765,
          "common_name" => "Calathea Orbifolia",
          "scientific_name" => ["Goeppertia orbifolia"],
          "sunlight" => ["part shade"],
          "watering" => "Average",
          "default_image" => {
            "regular_url" => "https://example.com/calathea.jpg"
          }
        }
      end

      def plant_details
        plant_with_image.merge(
          "description" => "A leafy indoor plant.",
          "care_level" => "Medium",
          "poisonous_to_pets" => false
        )
      end
    end

    class PagedPerenualClient < FakePerenualClient
      def initialize(per_page:)
        super()
        @per_page = per_page
      end

      def species_list(params = {})
        species_list_params << params
        first_id = params[:page] * 100

        {
          "data" => Array.new(@per_page) do |index|
            plant_with_image.merge("id" => first_id + index, "common_name" => "Plant #{first_id + index}",
                                   "scientific_name" => ["Species #{first_id + index}"])
          end,
          "last_page" => 5
        }
      end
    end

    # A search list entry with no care fields
    class ListOnlyPerenualClient < FakePerenualClient
      def species_list(params = {})
        species_list_params << params

        {
          "data" => [plant_with_image.except("sunlight", "watering")],
          "last_page" => 1
        }
      end
    end

    class DuplicatePerenualClient < FakePerenualClient
      def species_list(params = {})
        species_list_params << params

        {
          "data" => [
            plant_with_image.merge("id" => 98765),
            plant_with_image.merge("id" => 11111, "common_name" => "Calathea Orbifolia Duplicate")
          ],
          "last_page" => 1
        }
      end
    end
  end
end
