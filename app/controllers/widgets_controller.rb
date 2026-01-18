class WidgetsController < ApplicationController
  before_action :set_widget, only: %i[ show edit update destroy ]
  before_action :authorize_owner!, only: %i[ edit update destroy ]

  # GET /widgets or /widgets.json
  def index
    @owned_widgets = Widget.owned_by(current_user).order(created_at: :desc)
    @shared_widgets = Widget.shared_with(current_user).order(created_at: :desc)
    @public_widgets = Widget.where(is_public: true)
                            .where.not(id: @owned_widgets.select(:id))
                            .where.not(id: @shared_widgets.select(:id))
                            .order(created_at: :desc)
    @data_sources = DataSource.accessible_for(current_user)
  end

  # GET /widgets/1 or /widgets/1.json
  def show
    render partial: "show_modal", layout: false
  end

  # GET /widgets/new
  def new
    @widget = Widget.new
    @data_sources = DataSource.accessible_for(current_user)
    render partial: "new_modal", layout: false
  end

  # GET /widgets/1/edit
  def edit
    @data_sources = DataSource.accessible_for(current_user)
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
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # POST /widgets or /widgets.json
  def create
    @widget = Widget.new(widget_params.except(:data_source_id, :transformer_config))

    respond_to do |format|
      if @widget.save
        # Setze den aktuellen User als Owner
        @widget.add_owner(current_user)

        # Erstelle den WidgetDataSourceTransformer, wenn eine Datenquelle ausgewählt wurde
        if params[:widget][:data_source_id].present?
          @widget.create_widget_data_source_transformer!(
            data_source_id: params[:widget][:data_source_id],
            config: build_transformer_config
          )
        end

        format.turbo_stream do
          @owned_widgets = Widget.owned_by(current_user).order(created_at: :desc)
          @shared_widgets = Widget.shared_with(current_user).order(created_at: :desc)
          @public_widgets = Widget.where(is_public: true)
                                   .where.not(id: (@owned_widgets.pluck(:id) + @shared_widgets.pluck(:id)))
                                   .order(created_at: :desc)
          render :crud_success
        end
        format.html { redirect_to @widget, notice: "Widget wurde erfolgreich erstellt." }
        format.json { render :show, status: :created, location: @widget }
      else
        @data_sources = DataSource.all
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @widget.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /widgets/1 or /widgets/1.json
  def update
    # Validiere Zugriffsrechte nur wenn Widget nicht öffentlich ist
    is_public = params.dig(:widget, :is_public) == "1"
    
    unless is_public
      user_roles = params.dig(:access, :user_roles) || {}
      future_owner_count = user_roles.values.count { |role| role == 'owner' }
      
      if future_owner_count == 0
        # Lade notwendige Variablen für edit_modal
        @data_sources = DataSource.accessible_for(current_user)
        @users = User.order(:email)
        @roles = UserWidgetRole.roles.keys
        @user_widget_roles = @widget.user_widget_roles.includes(:user).index_by(&:user_id)
        
        flash.now[:alert] = "Es muss mindestens einen Owner geben."
        render partial: "edit_modal", layout: false
        return
      end
    end

    respond_to do |format|
      if @widget.update(widget_params.except(:data_source_id, :transformer_config))
        # Aktualisiere die Datenquelle im Transformer
        if params[:widget][:data_source_id].present?
          if @widget.widget_data_source_transformer.present?
            @widget.widget_data_source_transformer.update(
              data_source_id: params[:widget][:data_source_id],
              config: build_transformer_config
            )
          else
            @widget.create_widget_data_source_transformer!(
              data_source_id: params[:widget][:data_source_id],
              config: build_transformer_config
            )
          end
        end

        # Aktualisiere Zugriffsrechte nur wenn Widget nicht öffentlich ist
        unless is_public
          user_roles = params.dig(:access, :user_roles) || {}
          ActiveRecord::Base.transaction do
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
        end

        format.turbo_stream do
          @widget.reload  # Widget neu laden, um die aktualisierten Daten zu zeigen
          @owned_widgets = Widget.owned_by(current_user).order(created_at: :desc)
          @shared_widgets = Widget.shared_with(current_user).order(created_at: :desc)
          @public_widgets = Widget.where(is_public: true)
                                   .where.not(id: (@owned_widgets.pluck(:id) + @shared_widgets.pluck(:id)))
                                   .order(created_at: :desc)
          render :crud_success
        end
        format.html { redirect_to @widget, notice: "Widget wurde erfolgreich aktualisiert.", status: :see_other }
        format.json { render :show, status: :ok, location: @widget }
      else
        @data_sources = DataSource.all
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @widget.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /widgets/1 or /widgets/1.json
  def destroy
    @widget.destroy!

    respond_to do |format|
      format.turbo_stream do
        @owned_widgets = Widget.owned_by(current_user).order(created_at: :desc)
        @shared_widgets = Widget.shared_with(current_user).order(created_at: :desc)
        @public_widgets = Widget.where(is_public: true)
                                 .where.not(id: (@owned_widgets.pluck(:id) + @shared_widgets.pluck(:id)))
                                 .order(created_at: :desc)
      end
      format.html { redirect_to widgets_path, notice: "Widget was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_widget
      @widget = Widget.find(params.expect(:id))
    end

    def authorize_owner!
      unless @widget.can_edit?(current_user)
        redirect_to widgets_path, alert: "Sie haben keine Berechtigung, dieses Widget zu bearbeiten."
      end
    end

    # Only allow a list of trusted parameters through.
    def widget_params
      params.expect(widget: [ 
        :name, :description, :widget_type, :color, :is_public, :data_source_id,
        :time_range_value, :time_range_unit, :data_limit, :group_by, :aggregate_function, :unit
      ])
    end

    # Baut die Transformer-Config aus den Form-Parametern
    def build_transformer_config
      config = {}
      transformer_config = params[:widget][:transformer_config] || {}
      
      # Nur nicht-leere Werte übernehmen
      config['json_path'] = transformer_config[:json_path] if transformer_config[:json_path].present?
      config['multiply'] = transformer_config[:multiply].to_f if transformer_config[:multiply].present?
      config['add'] = transformer_config[:add].to_f if transformer_config[:add].present?
      config['round'] = transformer_config[:round].to_i if transformer_config[:round].present?
      config['format'] = transformer_config[:format] if transformer_config[:format].present?
      
      config
    end
end
