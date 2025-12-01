class DashboardUserRole < ApplicationRecord
  belongs_to :dashboard
  belongs_to :user

  enum :role, { viewer: 0, editor: 1, owner: 2 }

  validates :user_id, uniqueness: { scope: :dashboard_id, message: "ist bereits Mitglied dieses Dashboards" }
  validates :role, presence: true

end
