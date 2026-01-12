class DashboardsController < ApplicationController
  before_action :set_dashboard, only: %i[ show edit update destroy ]

  # GET /dashboards or /dashboards.json
  def index
    @owned_dashboards = Dashboard.owned_by(current_user)
    @shared_dashboards = Dashboard.shared_with(current_user)
    @public_dashboards = Dashboard.where(is_public: true)
                                  .where.not(id: @owned_dashboards.select(:id))
                                  .where.not(id: @shared_dashboards.select(:id))
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
        # Ersteller wird automatisch Owner
        @dashboard.dashboard_user_roles.create!(user: current_user, role: :owner)
        format.html { redirect_to @dashboard, notice: "Dashboard wurde erfolgreich erstellt." }
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
