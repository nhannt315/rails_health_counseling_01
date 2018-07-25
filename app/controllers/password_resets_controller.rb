class PasswordResetsController < ApplicationController
  before_action :get_user, :valid_user, :check_expiration,
    only: [:edit, :update]

  def new; end

  def edit; end

  def create
    @user = User.find_by email: params[:password_reset][:email].downcase

    if @user
      @user.create_reset_digest
      @user.send_mail :password_reset
      flash[:info] = I18n.t "forgot_password.info"
      redirect_to root_url
    else
      flash.now[:danger] = I18n.t "forgot_password.not_found"
      render :new
    end
  end

  def update
    unless @user
      flash[:message] = I18n.t "error.page_not_found_content"
      render "shared/404"
    end
    if params[:user][:password].empty?
      @user.errors.add I18n.t("forgot_password.user_error_add")
      render :edit
    elsif @user.update_attributes user_params
      log_in @user
      flash[:success] = I18n.t "forgot_password.success"
      redirect_to @user
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit :password, :password_confirmation
  end

  def get_user
    @user = User.find_by email: params[:email]
  end

  def valid_user
    return if @user&.activated? && @user.authenticated?(:reset, params[:id])
    redirect_to root_url
  end

  def check_expiration
    return unless @user.password_reset_expired?
    flash[:danger] = I18n.t "forgot_password.expired"
    redirect_to new_password_reset_url
  end
end