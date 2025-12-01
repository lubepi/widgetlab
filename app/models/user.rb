class User < ApplicationRecord
  has_many :dashboard_user_roles, dependent: :destroy
  has_many :dashboards, through: :dashboard_user_roles, source: :dashboard

  has_many :user_group_roles, dependent: :destroy
  has_many :user_groups, through: :user_group_roles, source: :user_group
end
