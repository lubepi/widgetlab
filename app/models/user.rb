class User < ApplicationRecord
  has_many :dashboard_user_roles, dependent: :destroy
  has_many :dashboards, through: :dashboard_user_roles, source: :dashboard
end
