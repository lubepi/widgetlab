class DashboardsController < ApplicationController
  before_action :set_dashboard, only: %i[ show edit update destroy update_widget_positions ]

  # GET /dashboards or /dashboards.json
  def index
    @dashboards = Dashboard.all
  end

  # GET /dashboards/1 or /dashboards/1.json
  def show
  end

  # GET /dashboards/new
  def new
    @dashboard = Dashboard.new
  end

  # GET /dashboards/1/edit
  def edit
  end

  # POST /dashboards or /dashboards.json
  def create
    @dashboard = Dashboard.new(dashboard_params)

    respond_to do |format|
      if @dashboard.save
        format.html { redirect_to @dashboard, notice: "Dashboard was successfully created." }
        format.json { render :show, status: :created, location: @dashboard }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @dashboard.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dashboards/1 or /dashboards/1.json
  def update
    respond_to do |format|
      if @dashboard.update(dashboard_params)
        format.html { redirect_to @dashboard, notice: "Dashboard was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @dashboard }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @dashboard.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dashboards/1 or /dashboards/1.json
  def destroy
    @dashboard.destroy!

    respond_to do |format|
      format.html { redirect_to dashboards_path, notice: "Dashboard was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # PATCH /dashboards/1/update_widget_positions
  def update_widget_positions
    positions = params[:positions] || []
    
    positions.each do |pos|
      widget = @dashboard.dashboard_widgets.find_by(id: pos[:id])
      if widget
        widget.update(
          position_x: pos[:position].to_i,
          position_y: pos[:position].to_i,
          width: pos[:width].to_i,
          height: pos[:height].to_i
        )
      end
    end

    respond_to do |format|
      format.json { head :ok }
      format.html { redirect_to @dashboard }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dashboard
      @dashboard = Dashboard.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def dashboard_params
      params.expect(dashboard: [ :name, :columns, :is_public, :icon ])
    end
end
