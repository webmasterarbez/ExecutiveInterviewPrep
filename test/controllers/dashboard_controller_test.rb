require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "lists the current user's interview requests" do
    user = users(:one)
    post login_path, params: { email: user.email, password: "password" }

    get dashboard_path

    assert_response :success
    assert_includes response.body, "Board interview with Acme Robotics"
  end

  test "shows only the current user's requests" do
    user = users(:two)
    post login_path, params: { email: user.email, password: "password" }

    get dashboard_path

    assert_response :success
    assert_not_includes response.body, "Board interview with Acme Robotics"
  end

  test "requires authentication" do
    get dashboard_path

    assert_redirected_to login_path
  end
end
