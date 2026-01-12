class WidgetsController < ApplicationController
  before_action :set_widget, only: %i[ show edit update destroy ]

  # GET /widgets or /widgets.json
  def index
    @widgets = Widget.all
    @data_sources = DataSource.all
  end

  # GET /widgets/1 or /widgets/1.json
  def show
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /widgets/new
  def new
    @widget = Widget.new
    @data_sources = DataSource.all
  end

  # GET /widgets/1/edit
  def edit
    @data_sources = DataSource.all
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
        # Erstelle den WidgetDataSourceTransformer, wenn eine Datenquelle ausgewählt wurde
        if params[:widget][:data_source_id].present?
          @widget.create_widget_data_source_transformer!(
            data_source_id: params[:widget][:data_source_id],
            config: build_transformer_config
          )
        end

        format.turbo_stream do
          @widgets = Widget.all
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

        format.turbo_stream do
          @widgets = Widget.all
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
      format.html { redirect_to widgets_path, notice: "Widget was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_widget
      @widget = Widget.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def widget_params
      params.expect(widget: [ 
        :name, :description, :widget_type, :color, :is_public, :data_source_id,
        :time_range_value, :time_range_unit, :data_limit, :group_by, :aggregate_function
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
