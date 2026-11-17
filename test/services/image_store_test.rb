require "test_helper"

class ImageStoreTest < ActiveSupport::TestCase
  # The worked example in Cloudinary's signature docs
  test "signs upload parameters the way Cloudinary expects" do
    store = ImageStore.new(url: "cloudinary://123456:abcd@demo")
    params = { eager: "w_400,h_300,c_pad|w_260,h_200,c_crop", public_id: "sample_image", timestamp: "1315060510" }

    assert_equal "bfd09f95f331f558cbd1320e67aa8d488770583e", store.send(:signature, params)
  end

  test "pages get a resized copy" do
    url = "https://res.cloudinary.com/demo/image/upload/v1/plant-match/perenual-425.jpg"

    assert_equal "https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,c_limit,w_1000/v1/plant-match/perenual-425.jpg",
                 ImageStore.display_url(url)
  end
end
