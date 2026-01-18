class Dashboard < ApplicationRecord
  has_many :dashboard_user_roles, dependent: :destroy
  has_many :members, through: :dashboard_user_roles, source: :user

  has_many :dashboard_group_roles, dependent: :destroy
  has_many :member_groups, through: :dashboard_group_roles, source: :user_group

  has_many :dashboard_widgets, dependent: :destroy
  has_many :widgets, through: :dashboard_widgets, source: :widget

  # Dashboards die dem User gehören (owner) - direkt oder über Gruppen
  scope :owned_by, ->(user) {
    group_ids = user.user_groups.select(:id)
    
    left_outer_joins(:dashboard_user_roles, :dashboard_group_roles)
      .where("dashboard_user_roles.user_id = ? AND dashboard_user_roles.role = ? OR dashboard_group_roles.user_group_id IN (?) AND dashboard_group_roles.role = ?",
             user.id, DashboardUserRole.roles[:owner], group_ids, DashboardGroupRole.roles[:owner])
      .distinct
  }

  # Dashboards die mit dem User geteilt wurden (viewer oder editor, aber nicht owner) - direkt oder über Gruppen
  scope :shared_with, ->(user) {
    group_ids = user.user_groups.select(:id)
    
    # Hole alle Dashboards wo User Zugriff hat
    accessible = left_outer_joins(:dashboard_user_roles, :dashboard_group_roles)
      .where("dashboard_user_roles.user_id = ? AND dashboard_user_roles.role IN (?) OR dashboard_group_roles.user_group_id IN (?) AND dashboard_group_roles.role IN (?)",
             user.id, [DashboardUserRole.roles[:viewer], DashboardUserRole.roles[:editor]], 
             group_ids, [DashboardGroupRole.roles[:viewer], DashboardGroupRole.roles[:editor]])
      .distinct
    
    # Schließe Dashboards aus, wo User Owner ist
    accessible.where.not(id: owned_by(user).select(:id))
  }

  # Alle Dashboards auf die der User Zugriff hat
  scope :accessible_by, ->(user) {
    left_outer_joins(:dashboard_user_roles, :dashboard_group_roles)
      .where("dashboards.is_public = TRUE OR dashboard_user_roles.user_id = ? OR dashboard_group_roles.user_group_id IN (?)", 
             user.id, user.user_groups.select(:id))
      .distinct
  }

  # Rolle eines Users für dieses Dashboard (berücksichtigt auch Gruppen)
  def role_for(user)
    # Direkte User-Rolle
    user_role = dashboard_user_roles.find_by(user_id: user.id)&.role
    return user_role if user_role.present?
    
    # Gruppen-Rolle (höchste Rolle aus allen Gruppen)
    group_roles = dashboard_group_roles
      .joins(:user_group)
      .joins("INNER JOIN user_group_roles ON user_group_roles.user_group_id = dashboard_group_roles.user_group_id")
      .where(user_group_roles: { user_id: user.id })
      .pluck(:role)
    
    return nil if group_roles.empty?
    
    # Gib die höchste Rolle zurück (owner > editor > viewer)
    return "owner" if group_roles.include?("owner")
    return "editor" if group_roles.include?("editor")
    return "viewer" if group_roles.include?("viewer")
    nil
  end

  # Prüft ob User Owner ist
  def owner?(user)
    role_for(user) == "owner"
  end

  # Prüft ob User bearbeiten darf (editor oder owner)
  def can_edit?(user)
    %w[editor owner].include?(role_for(user))
  end

  # Prüft ob User Zugriff hat (berücksichtigt auch Gruppen)
  def can_view?(user)
    return true if is_public
    return false if user.nil?
    
    # Prüfe direkte User-Rolle
    return true if dashboard_user_roles.exists?(user_id: user.id)
    
    # Prüfe Gruppen-Rollen
    group_ids = user.user_groups.pluck(:id)
    dashboard_group_roles.exists?(user_group_id: group_ids)
  end
end
