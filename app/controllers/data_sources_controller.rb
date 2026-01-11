class DataSourcesController < ApplicationController
  before_action :set_data_source, only: %i[ show edit update destroy ]

  # GET /data_sources or /data_sources.json
  def index
    @data_sources = DataSource.all
  end

  # GET /data_sources/1 or /data_sources/1.json
  def show
    redirect_to edit_data_source_path(@data_source)
  end

  # GET /data_sources/new
  def new
    @data_source = DataSource.new
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /data_sources/1/edit
  def edit
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # POST /data_sources or /data_sources.json
  def create
    @data_source = DataSource.new(data_source_params)
    @data_source.creator = current_user

    respond_to do |format|
      if @data_source.save
        format.turbo_stream do
          @data_sources = DataSource.all
          render :crud_success
        end
        format.html { redirect_to data_sources_path, notice: "Datenquelle wurde erfolgreich erstellt." }
        format.json { render :show, status: :created, location: @data_source }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :form_update, status: :unprocessable_entity }
        format.json { render json: @data_source.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /data_sources/1 or /data_sources/1.json
  def update
    respond_to do |format|
      if @data_source.update(data_source_params)
        format.turbo_stream do
          @data_sources = DataSource.all
          render :crud_success
        end
        format.html { redirect_to data_sources_path, notice: "Datenquelle wurde erfolgreich aktualisiert.", status: :see_other }
        format.json { render :show, status: :ok, location: @data_source }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :form_update, status: :unprocessable_entity }
        format.json { render json: @data_source.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /data_sources/1 or /data_sources/1.json
  def destroy
    @data_source.destroy!

    respond_to do |format|
      format.html { redirect_to data_sources_path, notice: "Datenquelle wurde erfolgreich gelöscht.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # GET /data_sources/config_fields
  def config_fields
    @data_source = DataSource.new(source_type: params[:type])
    render partial: "config_fields_#{params[:type]}_content", locals: { data_source: @data_source }, layout: false
  end

  def start_subscription
    @data_source = DataSource.find(params.expect(:id))

    @data_source.update!(config: (@data_source.config || {}).merge(auto_subscribe: true))

    DataSources::ManagerService.subscribe(@data_source) unless @data_source.job_running?

    @data_sources = DataSource.all

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "data_sources_table",
          partial: "data_sources/table",
          locals: { data_sources: @data_sources }
        )
      end
      format.html { redirect_to data_sources_path, notice: "Datenquelle wurde gestartet." }
    end
  end

  def stop_subscription
    @data_source = DataSource.find(params.expect(:id))

    @data_source.update!(config: (@data_source.config || {}).merge(auto_subscribe: false))

    DataSources::ManagerService.unsubscribe(@data_source)
    @data_source.update(status: :inactive, last_error: nil)

    @data_sources = DataSource.all

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "data_sources_table",
          partial: "data_sources/table",
          locals: { data_sources: @data_sources }
        )
      end
      format.html { redirect_to data_sources_path, notice: "Datenquelle wurde gestoppt." }
    end
  end

  def start_all_subscriptions
    DataSource.find_each do |data_source|
      data_source.update!(config: (data_source.config || {}).merge(auto_subscribe: true))
      DataSources::ManagerService.subscribe(data_source) unless data_source.job_running?
    end

    @data_sources = DataSource.all

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "data_sources_table",
          partial: "data_sources/table",
          locals: { data_sources: @data_sources }
        )
      end
      format.html { redirect_to data_sources_path, notice: "Alle Datenquellen wurden gestartet." }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_data_source
      @data_source = DataSource.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def data_source_params
      params.require(:data_source).permit(
        :name, 
        :source_type, 
        :is_public,
        config: [
          :host, :port, :topic, :username, :password, :client_id, 
          :clean_session, :keep_alive, :qos, :parse_json,
          :use_ssl, :ca_file, :cert_file, :key_file,
          :url, :method, :headers, :query_params, :body, 
          :timeout, :interval, :json_path, :bearer_token,
          auth: [:username, :password]
        ]
      ).tap do |whitelisted|
        # Convert JSON strings to hashes for headers, query_params, and body
        if whitelisted[:config].present?
          [:headers, :query_params].each do |key|
            if whitelisted[:config][key].is_a?(String) && whitelisted[:config][key].present?
              begin
                whitelisted[:config][key] = JSON.parse(whitelisted[:config][key])
              rescue JSON::ParserError
                # Keep as string if parsing fails
              end
            end
          end
          
          # Handle body - can be string or JSON
          if whitelisted[:config][:body].is_a?(String) && whitelisted[:config][:body].present?
            begin
              whitelisted[:config][:body] = JSON.parse(whitelisted[:config][:body])
            rescue JSON::ParserError
              # Keep as string if parsing fails
            end
          end
        end
      end
    end
end
