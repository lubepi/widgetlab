class UserWidgetRolesController < ApplicationController
  before_action :set_widget

  def edit
    @users = User.order(:email)
    @roles = UserWidgetRole.roles.keys
    @user_widget_roles = @widget.user_widget_roles.includes(:user).index_by(&:user_id)
    
    # Sortiere Benutzer nach Zugriffslevel (Owner > Viewer > Kein Zugriff)
    @users = @users.sort_by do |user|
      role = @user_widget_roles[user.id]&.role
      case role
      when 'owner'
        0
      when 'viewer'
        1
      else
        2
      end
    end
  end

  def update
    user_roles = params.dig(:access, :user_roles) || {}
    is_public = params.dig(:widget, :is_public) == '1'
    
    # Zähle wie viele Owner es nach dem Update geben würde
    future_owner_count = 0
    user_roles.each do |_, role|
      future_owner_count += 1 if role == 'owner'
    end
    
    if future_owner_count == 0
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("widget_modal") { render partial: "edit" } }
        format.html { redirect_to access_widget_path(@widget), alert: "Es muss mindestens einen Owner geben." }
      end
      return
    end

    begin
      ActiveRecord::Base.transaction do
        # Öffentliche Sichtbarkeit aktualisieren
        @widget.update!(is_public: is_public)
        
        # Bestehende Rollen aktualisieren oder entfernen
        @widget.user_widget_roles.each do |uwr|
          new_role = user_roles[uwr.user_id.to_s]
          if new_role.blank?
            uwr.destroy!
          elsif uwr.role != new_role
            uwr.update!(role: new_role)
          end
        end

        # Neue Rollen hinzufügen
        user_roles.each do |user_id, role|
          next if role.blank?
          next if @widget.user_widget_roles.exists?(user_id: user_id)
          @widget.user_widget_roles.create!(user_id: user_id, role: role)
        end
      end

      respond_to do |format|
        format.turbo_stream do
          @owned_widgets = Widget.owned_by(current_user).order(created_at: :desc)
          @shared_widgets = Widget.shared_with(current_user).order(created_at: :desc)
          @public_widgets = Widget.where(is_public: true)
                                   .where.not(id: (@owned_widgets.pluck(:id) + @shared_widgets.pluck(:id)))
                                   .order(created_at: :desc)
        end
        format.html { redirect_to widgets_path, notice: "Zugriffsrechte wurden aktualisiert." }
      end
    rescue ActiveRecord::RecordInvalid => e
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("widget_modal") { render partial: "edit" } }
        format.html { redirect_to access_widget_path(@widget), alert: e.message }
      end
    end
  end

  private

  def set_widget
    @widget = Widget.find(params[:id])
  end
end
