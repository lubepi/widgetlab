class DataSourceWhitelistsController < ApplicationController
  before_action :set_data_source

  def edit
    if @data_source.is_public == true
      redirect_to data_sources_path, alert: "Öffentliche Datenquellen benötigen keine Whitelist.", status: :see_other
      return
    end

    @selected_user_ids = @data_source.data_source_whitelists.where(whitelistable_type: "User").pluck(:whitelistable_id)
    @selected_user_group_ids = @data_source.data_source_whitelists.where(whitelistable_type: "UserGroup").pluck(:whitelistable_id)

    @users = User.order(:email)
    @user_groups = UserGroup.includes(:members).order(:name)
    @group_member_info = @user_groups.to_h { |g| [g.id, { name: g.name, member_ids: g.members.map(&:id) }] }
  end

  def update
    if @data_source.is_public == true
      redirect_to data_sources_path, alert: "Öffentliche Datenquellen benötigen keine Whitelist.", status: :see_other
      return
    end

    user_ids = Array(params.dig(:whitelist, :user_ids)).map(&:to_s).map(&:strip).reject(&:blank?).map(&:to_i)
    user_group_ids = Array(params.dig(:whitelist, :user_group_ids)).map(&:to_s).map(&:strip).reject(&:blank?).map(&:to_i)

    ActiveRecord::Base.transaction do
      sync_whitelist!("User", user_ids)
      sync_whitelist!("UserGroup", user_group_ids)
    end

    @data_sources = DataSource.all

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Whitelist wurde erfolgreich aktualisiert."
        render "data_sources/crud_success"
      end
      format.html { redirect_to data_sources_path, notice: "Whitelist wurde erfolgreich aktualisiert.", status: :see_other }
    end
  end

  private

  def set_data_source
    @data_source = DataSource.find(params.expect(:id))
  end

  def sync_whitelist!(whitelistable_type, new_ids)
    scope = @data_source.data_source_whitelists.where(whitelistable_type: whitelistable_type)
    current_ids = scope.pluck(:whitelistable_id)

    (current_ids - new_ids).each do |remove_id|
      scope.where(whitelistable_id: remove_id).delete_all
    end

    (new_ids - current_ids).each do |add_id|
      @data_source.data_source_whitelists.create!(whitelistable_type: whitelistable_type, whitelistable_id: add_id)
    end
  end
end
