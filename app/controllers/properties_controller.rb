class PropertiesController < ApplicationController
  before_action :authenticate_account!, only: [:new, :create, :edit, :update, :destroy, :mine]
  before_action :set_property, only: [:show, :edit, :update, :destroy]
  before_action :authorize_property_owner!, only: [:edit, :update, :destroy]
  before_action :set_sidebar, only: [:new, :create, :edit, :update, :destroy, :mine]

  # GET /properties
  # GET /properties.json
  def index
    if request.format.html?
      @show_sidebar = nil # Public catalogue even when owner is signed in
      @catalog = PropertyCatalogQuery.new(params)
      @properties = @catalog.records
      return render :catalog
    end
    @properties = Property.order(created_at: :desc)
  end

  def mine
    @properties = current_account.properties.order(created_at: :desc)
  end

  # GET /properties/1
  # GET /properties/1.json
  def show
    if request.format.html?
      @related_properties = Property.where(account_id: @property.account_id, status: "available")
        .where.not(id: @property.id).order(created_at: :desc).limit(3)
      return render :detail
    end
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
    if @property.destroy
      respond_to do |format|
        format.html { redirect_to properties_url, notice: 'Property was successfully destroyed.' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to my_properties_path,
          alert: 'This listing cannot be deleted while it has associated enquiries.' }
        format.json { render json: { errors: @property.errors.full_messages },
          status: :unprocessable_entity }
      end
    end
  end

  # Compatibility route for historical listing contact forms. Even this legacy
  # endpoint now persists a validated Enquiry before attempting email delivery.
  def email_agent
    property = Property.find_by(id: params[:property_id])
    return head :not_found unless property

    first_name = params[:first_name].to_s.strip
    last_name = params[:last_name].to_s.strip
    if first_name.blank? || last_name.blank? ||
        first_name.length > 100 || last_name.length > 100
      return head :unprocessable_entity
    end

    return head :no_content if params[:website].present?

    enquiry = property.enquiries.build(
      name: "#{first_name} #{last_name}",
      email: params[:email],
      message: params[:message]
    )
    return head :unprocessable_entity unless enquiry.valid?

    recent = Enquiry.where(property_id: property.id, email: enquiry.email)
      .where("created_at >= ?", 1.hour.ago)
    return head :too_many_requests if recent.count >= 3

    return head :unprocessable_entity unless enquiry.save

    begin
      EnquiryMailer.with(enquiry_id: enquiry.id).new_enquiry.deliver_now
    rescue StandardError => error
      Rails.logger.error("Legacy enquiry notification failed (id=#{enquiry.id}, error=#{error.class})")
    end

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
