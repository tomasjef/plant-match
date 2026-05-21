require "test_helper"

class DevisePagesTest < ActionDispatch::IntegrationTest
  test "should get login page" do
    get new_user_session_url
    assert_response :success
  end

  test "should get sign up page" do
    get new_user_registration_url
    assert_response :success
  end
end
