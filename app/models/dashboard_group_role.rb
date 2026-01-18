class DashboardGroupRole < ApplicationRecord
  belongs_to :dashboard
  belongs_to :user_group

  enum :role, { viewer: 0, editor: 1, owner: 2 }

  validates :user_group_id, uniqueness: { scope: :dashboard_id, message: "ist bereits Mitglied dieses Dashboards" }
  validates :role, presence: true
end
