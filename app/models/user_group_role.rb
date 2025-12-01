class UserGroupRole < ApplicationRecord
  belongs_to :user_group
  belongs_to :user

  enum :role, { member: 0, editor: 1, owner: 2 }

  validates :user_id, uniqueness: { scope: :user_group_id, message: "ist bereits Mitglied dieser Nutzergruppe" }
end
