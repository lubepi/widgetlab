class UserGroup < ApplicationRecord
  has_many :user_group_roles, dependent: :destroy
  has_many :members, through: :user_group_roles, source: :user
end
