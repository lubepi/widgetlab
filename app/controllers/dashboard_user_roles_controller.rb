class DashboardUserRolesController < ApplicationController
  before_action :set_dashboard

  def edit
    @users = User.order(:email)
    @user_groups = UserGroup.order(:name)
    @roles = DashboardUserRole.roles.keys
    @dashboard_user_roles = @dashboard.dashboard_user_roles.includes(:user).index_by(&:user_id)
    @dashboard_group_roles = @dashboard.dashboard_group_roles.includes(:user_group).index_by(&:user_group_id)
  end

  def update
    user_roles = params.dig(:access, :user_roles) || {}
    group_roles = params.dig(:access, :group_roles) || {}
    
    # Zähle wie viele Owner es nach dem Update geben würde (Benutzer + Gruppen)
    future_owner_count = 0
    user_roles.each do |_, role|
      future_owner_count += 1 if role == 'owner'
    end
    group_roles.each do |_, role|
      future_owner_count += 1 if role == 'owner'
    end
    
    if future_owner_count == 0
      redirect_to access_dashboard_path(@dashboard), alert: "Es muss mindestens einen Owner geben."
      return
    end

    ActiveRecord::Base.transaction do
      # Bestehende User-Rollen aktualisieren oder entfernen
      @dashboard.dashboard_user_roles.each do |dur|
        new_role = user_roles[dur.user_id.to_s]
        if new_role.blank?
          dur.destroy!
        elsif dur.role != new_role
          dur.update!(role: new_role)
        end
      end

      # Neue User-Rollen hinzufügen
      user_roles.each do |user_id, role|
        next if role.blank?
        next if @dashboard.dashboard_user_roles.exists?(user_id: user_id)
        @dashboard.dashboard_user_roles.create!(user_id: user_id, role: role)
      end
      
      # Bestehende Gruppen-Rollen aktualisieren oder entfernen
      @dashboard.dashboard_group_roles.each do |dgr|
        new_role = group_roles[dgr.user_group_id.to_s]
        if new_role.blank?
          dgr.destroy!
        elsif dgr.role != new_role
          dgr.update!(role: new_role)
        end
      end

      # Neue Gruppen-Rollen hinzufügen
      group_roles.each do |group_id, role|
        next if role.blank?
        next if @dashboard.dashboard_group_roles.exists?(user_group_id: group_id)
        @dashboard.dashboard_group_roles.create!(user_group_id: group_id, role: role)
      end
    end

    redirect_to @dashboard, notice: "Zugriffsrechte wurden aktualisiert."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to access_dashboard_path(@dashboard), alert: e.message
  end

  private

  def set_dashboard
    @dashboard = Dashboard.find(params[:id])
  end
end
