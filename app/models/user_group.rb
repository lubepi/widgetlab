class UserGroup < ApplicationRecord
  has_many :user_group_roles, dependent: :destroy
  has_many :members, through: :user_group_roles, source: :user

  has_many :data_source_whitelists, dependent: :destroy, as: :whitelistable
  has_many :dashboard_group_roles, dependent: :destroy
  has_many :dashboards, through: :dashboard_group_roles, source: :dashboard
end
