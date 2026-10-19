class PropertiesController < ApplicationController

  before_action :set_property, only: %i[show edit update destroy remove_involved_party]

  def index
    @properties = policy_scope(Property).includes(:user, :involved_party).all
  end

  def show
    authorize @property
  end

  def new
    @property = Property.new
    authorize @property
  end

  def create
    @property = Property.new(property_params)
    @property.user = current_user if defined?(current_user) && current_user.present?
    @property.user ||= User.first
    authorize @property

    if @property.save
      redirect_to @property, notice: "Property was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @property
  end

  def update
    authorize @property

    if @property.update(property_params)
      redirect_to @property, notice: "Property was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @property
    @property.destroy
    redirect_to properties_path, notice: "Property was successfully deleted."
  end

  def remove_involved_party
    authorize @property
    @property.update(involved_party_id: nil)
    redirect_back fallback_location: @property, notice: "Involved party was unassigned from this property."
  end

  private

  def set_property
    @property = Property.includes(:user, :involved_party, transactions: :chain).find(params[:id])
  end

  def property_params
    params.require(:property).permit(:house_number, :street, :second_line_of_address, :city, :post_code, :photo, :sold, :involved_party_id)
  end
end
