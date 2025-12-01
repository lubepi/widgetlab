class Dashboard < ApplicationRecord
  has_many :dashboard_user_roles, dependent: :destroy
  has_many :members, through: :dashboard_user_roles, source: :user

  has_many :dashboard_widgets, dependent: :destroy
  has_many :widgets, through: :dashboard_widgets, source: :widget
end
