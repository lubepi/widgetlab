class Dashboard < ApplicationRecord
  has_many :dashboard_user_roles, dependent: :destroy
  has_many :members, through: :dashboard_user_roles, source: :user

  has_many :dashboard_widgets, dependent: :destroy
  has_many :widgets, through: :dashboard_widgets, source: :widget

  # Dashboards die dem User gehören (owner)
  scope :owned_by, ->(user) {
    joins(:dashboard_user_roles)
      .where(dashboard_user_roles: { user_id: user.id, role: :owner })
  }

  # Dashboards die mit dem User geteilt wurden (viewer oder editor, aber nicht owner)
  scope :shared_with, ->(user) {
    joins(:dashboard_user_roles)
      .where(dashboard_user_roles: { user_id: user.id, role: [:viewer, :editor] })
  }

  # Alle Dashboards auf die der User Zugriff hat
  scope :accessible_by, ->(user) {
    left_outer_joins(:dashboard_user_roles)
      .where("dashboards.is_public = TRUE OR dashboard_user_roles.user_id = ?", user.id)
      .distinct
  }

  # Rolle eines Users für dieses Dashboard
  def role_for(user)
    dashboard_user_roles.find_by(user_id: user.id)&.role
  end

  # Prüft ob User Owner ist
  def owner?(user)
    role_for(user) == "owner"
  end

  # Prüft ob User bearbeiten darf (editor oder owner)
  def can_edit?(user)
    %w[editor owner].include?(role_for(user))
  end

  # Prüft ob User Zugriff hat
  def can_view?(user)
    is_public || dashboard_user_roles.exists?(user_id: user.id)
  end
end
