class Dashboard < ApplicationRecord
  has_many :dashboard_user_roles, dependent: :destroy
  has_many :members, through: :dashboard_user_roles, source: :user
end
