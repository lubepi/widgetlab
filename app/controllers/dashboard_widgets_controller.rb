class DashboardWidgetsController < ApplicationController
  before_action :set_dashboard, only: [:new, :create, :select_widget, :update_positions]
  before_action :set_dashboard_widget, only: [:edit, :update, :destroy]

  # GET /dashboard_widgets/new?dashboard_id=X
  # Modal zum Auswählen eines Widgets für ein Dashboard
  def new
    @dashboard_widget = @dashboard.dashboard_widgets.build
    @available_widgets = Widget.accessible_by(current_user)
                               .where.not(id: @dashboard.widget_ids)
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # POST /dashboard_widgets
  def create
    @dashboard_widget = @dashboard.dashboard_widgets.build(dashboard_widget_params)
    
    # Standardposition finden wenn nicht angegeben
    if @dashboard_widget.position_x.nil? || @dashboard_widget.position_y.nil?
      position = find_free_position(@dashboard)
      @dashboard_widget.position_x = position[:x]
      @dashboard_widget.position_y = position[:y]
    end
    
    # Standardgröße setzen wenn nicht angegeben
    @dashboard_widget.width ||= 2
    @dashboard_widget.height ||= 2

    respond_to do |format|
      if @dashboard_widget.save
        format.turbo_stream
        format.html { redirect_to @dashboard, notice: "Widget wurde hinzugefügt." }
        format.json { render json: @dashboard_widget, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @dashboard_widget.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /dashboard_widgets/:id/edit
  def edit
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # PATCH/PUT /dashboard_widgets/:id
  def update
    respond_to do |format|
      if @dashboard_widget.update(dashboard_widget_params)
        format.turbo_stream
        format.html { redirect_to @dashboard_widget.dashboard, notice: "Widget wurde aktualisiert." }
        format.json { render json: @dashboard_widget, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @dashboard_widget.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dashboard_widgets/:id
  def destroy
    dashboard = @dashboard_widget.dashboard
    @dashboard_widget.destroy!

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("dashboard_widget_#{@dashboard_widget.id}") }
      format.html { redirect_to dashboard, notice: "Widget wurde entfernt.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # PATCH /dashboards/:dashboard_id/dashboard_widgets/update_positions
  # Bulk Update der Positionen (für Drag & Drop)
  def update_positions
    positions = params[:positions] || []
    
    ActiveRecord::Base.transaction do
      positions.each do |pos|
        dw = @dashboard.dashboard_widgets.find_by(id: pos[:id])
        next unless dw
        
        dw.update!(
          position_x: pos[:position_x].to_i,
          position_y: pos[:position_y].to_i,
          width: [[pos[:width].to_i, 1].max, 4].min,  # Clamp zwischen 1 und 4
          height: [[pos[:height].to_i, 1].max, 4].min # Clamp zwischen 1 und 4
        )
      end
    end

    respond_to do |format|
      format.json { render json: { success: true } }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.json { render json: { success: false, error: e.message }, status: :unprocessable_entity }
    end
  end

  # GET /dashboards/:dashboard_id/select_widget
  # Modal zum Auswählen welches Widget hinzugefügt werden soll
  def select_widget
    @available_widgets = Widget.accessible_by(current_user)
                               .where.not(id: @dashboard.widget_ids)
    
    respond_to do |format|
      format.html { render layout: false }
      format.turbo_stream
    end
  end

  private

  def set_dashboard
    @dashboard = Dashboard.find(params[:dashboard_id])
  end

  def set_dashboard_widget
    @dashboard_widget = DashboardWidget.find(params[:id])
    @dashboard = @dashboard_widget.dashboard
  end

  def dashboard_widget_params
    params.require(:dashboard_widget).permit(:widget_id, :position_x, :position_y, :width, :height, :color)
  end

  def find_free_position(dashboard)
    columns = dashboard.columns || 12
    existing = dashboard.dashboard_widgets.pluck(:position_x, :position_y, :width, :height)
    
    # Suche von oben links nach unten rechts nach freiem Platz für 2x2 Widget
    (0..50).each do |y|
      (0..(columns - 2)).each do |x|
        fits = existing.none? do |ex_x, ex_y, ex_w, ex_h|
          ex_x ||= 0
          ex_y ||= 0
          ex_w ||= 1
          ex_h ||= 1
          # Prüfe ob es Überlappung gibt
          !(x + 2 <= ex_x || x >= ex_x + ex_w || y + 2 <= ex_y || y >= ex_y + ex_h)
        end
        return { x: x, y: y } if fits
      end
    end
    
    { x: 0, y: 0 }
  end
end
