ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  # Helper method to sign in a user for controller tests
  def sign_in(user)
    post login_path, params: {}, headers: {}
    session[:user_id] = user.id
  end

  # Alternative: set session directly in setup
  def sign_in_as(user)
    session[:user_id] = user.id
  end
end

# Module to help with authentication in controller tests
module AuthenticationHelper
  def sign_in(user)
    session[:user_id] = user.id
  end

  def sign_out
    session.delete(:user_id)
  end
end

class ActionController::TestCase
  include AuthenticationHelper
end
