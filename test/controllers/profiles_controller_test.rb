require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    post login_path, params: { email: @user.email, password: "password" }
  end

  test "updates name and phone number, normalizing to E.164" do
    patch "/profile/details", params: { name: "Avery Quinn", phone_number: "(415) 555-2671" }

    assert_redirected_to profile_path
    @user.reload
    assert_equal "Avery Quinn", @user.name
    assert_equal "+14155552671", @user.phone_number
  end

  test "rejects an invalid phone number and keeps the stored value" do
    patch "/profile/details", params: { name: "Avery Quinn", phone_number: "not-a-number" }

    assert_redirected_to profile_path
    assert_nil @user.reload.phone_number
  end

  test "requires authentication" do
    delete logout_path
    patch "/profile/details", params: { name: "Nope" }

    assert_redirected_to login_path
  end
end
