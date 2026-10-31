class PropertiesController < ApplicationController
  before_action :authenticate_account!, only: [:new, :create, :edit, :update, :destroy, :mine]
  before_action :set_property, only: [:show, :edit, :update, :destroy]
  before_action :authorize_property_owner!, only: [:edit, :update, :destroy]
  before_action :set_sidebar, only: [:new, :create, :edit, :update, :destroy, :mine]

  # GET /properties
  # GET /properties.json
  def index
    @properties = Property.order(created_at: :desc)
  end

  def mine
    @properties = current_account.properties.order(created_at: :desc)
  end

  # GET /properties/1
  # GET /properties/1.json
  def show
    @agent = @property.account
    @agent_properties = Property.where(account_id: @agent.id).where.not(id: @property.id)
  end

  # GET /properties/new
  def new
    @property = Property.new
  end

  # GET /properties/1/edit
  def edit
  end

  # POST /properties
  # POST /properties.json
  def create
    @property = Property.new(property_params)
    @property.account_id = current_account.id

    respond_to do |format|
      if @property.save
        format.html { redirect_to @property, notice: 'Property was successfully created.' }
        format.json { render :show, status: :created, location: @property }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @property.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /properties/1
  # PATCH/PUT /properties/1.json
  def update
    respond_to do |format|
      if @property.update(property_params)
        format.html { redirect_to @property, notice: 'Property was successfully updated.' }
        format.json { render :show, status: :ok, location: @property }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @property.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /properties/1
  # DELETE /properties/1.json
  def destroy
    @property.destroy
    respond_to do |format|
      format.html { redirect_to properties_url, notice: 'Property was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def email_agent
    profile_id = request.path_parameters[:profile_id]

    agent = if profile_id
      Account.find_by(id: profile_id)
    else
      Property.includes(:account).find_by(id: params[:property_id])&.account
    end

    return head :not_found unless agent

    first_name = params[:first_name].to_s.strip
    last_name = params[:last_name].to_s.strip
    email = params[:email].to_s.strip
    message = params[:message].to_s.strip

    valid = first_name.present? && first_name.length <= 100 &&
            last_name.present? && last_name.length <= 100 &&
            email.length <= 254 &&
            URI::MailTo::EMAIL_REGEXP.match?(email) &&
            message.present? && message.length <= 5000

    return head :unprocessable_entity unless valid

    ContactMailer.email_agent(
      agent, first_name, last_name, email, message
    ).deliver_now

    head :no_content
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_property
      @property = Property.find(params[:id])
    end

    def authorize_property_owner!
      head :forbidden unless @property.account_id == current_account.id
    end

    def set_sidebar
      @show_sidebar = true if account_signed_in?
    end

    # Only allow a list of trusted parameters through.
    def property_params
      params.require(:property).permit(
        :name,
        :address,
        :price,
        :rooms,
        :bathrooms,
        :photo,
        :photo_cache,
        :parking_spaces,
        :details,
        :for_sale,
        :available_date,
        :status
      )
    end
end
