require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes a national-format US phone number to E.164" do
    user = users(:two)
    user.update!(phone_number: "(212) 555-0123")

    assert_equal "+12125550123", user.phone_number
  end

  test "keeps an international E.164 phone number as entered" do
    user = users(:two)
    user.update!(phone_number: "+442071838750")

    assert_equal "+442071838750", user.phone_number
  end

  test "rejects an invalid phone number" do
    user = users(:two)
    user.phone_number = "123"

    assert_not user.valid?
    assert user.errors[:phone_number].present?
  end

  test "allows a blank phone number" do
    user = users(:two)
    user.phone_number = ""

    assert user.valid?
  end

  test "destroys dependent interview requests" do
    user = users(:one)
    assert user.interview_requests.any?

    assert_difference -> { InterviewRequest.count }, -user.interview_requests.count do
      user.destroy
    end
  end
end
