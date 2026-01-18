class UserGroupsController < ApplicationController
  before_action :set_user_group, only: %i[ show edit update destroy ]

  # GET /user_groups or /user_groups.json
  def index
    @user_groups = UserGroup.all
  end

  # GET /user_groups/1 or /user_groups/1.json
  def show
    redirect_to edit_user_group_path(@user_group)
  end

  # GET /user_groups/new
  def new
    @user_group = UserGroup.new
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /user_groups/1/edit
  def edit
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # POST /user_groups or /user_groups.json
  def create
    @user_group = UserGroup.new(user_group_params)

    respond_to do |format|
      if @user_group.save
        sync_members!

        format.turbo_stream do
          @user_groups = UserGroup.all
          render :crud_success
        end
        format.html { redirect_to user_groups_path, notice: t('user_groups.flash.created') }
        format.json { render :show, status: :created, location: @user_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :form_update, status: :unprocessable_entity }
        format.json { render json: @user_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /user_groups/1 or /user_groups/1.json
  def update
    respond_to do |format|
      if @user_group.update(user_group_params)
        sync_members!

        format.turbo_stream do
          @user_groups = UserGroup.all
          render :crud_success
        end
        format.html { redirect_to user_groups_path, notice: t('user_groups.flash.updated'), status: :see_other }
        format.json { render :show, status: :ok, location: @user_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :form_update, status: :unprocessable_entity }
        format.json { render json: @user_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /user_groups/1 or /user_groups/1.json
  def destroy
    @user_group.destroy!

    respond_to do |format|
      format.html { redirect_to user_groups_path, notice: t('user_groups.flash.destroyed'), status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user_group
      @user_group = UserGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def user_group_params
      params.require(:user_group).permit(:name, member_ids: [])
    end

    def sync_members!
      member_ids = Array(params.dig(:user_group, :member_ids)).reject(&:blank?).map(&:to_i)

      @user_group.transaction do
        @user_group.user_group_roles.where.not(user_id: member_ids).destroy_all
        member_ids.each do |user_id|
          @user_group.user_group_roles.find_or_create_by!(user_id: user_id) do |role|
            role.role = :member
          end
        end
      end
    end
end
