class DashboardWidgetsController < ApplicationController
  before_action :set_dashboard
  before_action :set_dashboard_widget, only: %i[update destroy]

  # POST /dashboards/:dashboard_id/widgets
  def create
    @dashboard_widget = @dashboard.dashboard_widgets.new(dashboard_widget_params)

    respond_to do |format|
      if @dashboard_widget.save
        format.html { redirect_to @dashboard, notice: "Widget wurde erfolgreich hinzugefügt." }
        format.json { render json: @dashboard_widget, status: :created }
      else
        format.html { redirect_to @dashboard, alert: "Widget konnte nicht hinzugefügt werden." }
        format.json { render json: @dashboard_widget.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dashboards/:dashboard_id/widgets/:id
  def update
    respond_to do |format|
      if @dashboard_widget.update(dashboard_widget_params)
        format.html { redirect_to @dashboard, notice: "Widget wurde erfolgreich aktualisiert." }
        format.json { render json: @dashboard_widget, status: :ok }
      else
        format.html { redirect_to @dashboard, alert: "Widget konnte nicht aktualisiert werden." }
        format.json { render json: @dashboard_widget.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dashboards/:dashboard_id/widgets/:id
  def destroy
    @dashboard_widget.destroy!

    respond_to do |format|
      format.html { redirect_to @dashboard, notice: "Widget wurde entfernt.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_dashboard
    @dashboard = Dashboard.find(params[:dashboard_id])
  end

  def set_dashboard_widget
    @dashboard_widget = @dashboard.dashboard_widgets.find(params[:id])
  end

  def dashboard_widget_params
    params.require(:dashboard_widget).permit(:widget_id, :position_x, :position_y, :width, :height, :color)
  end
end
