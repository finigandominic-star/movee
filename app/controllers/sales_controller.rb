# Guided "new sale" flow: vendor → property → buyer → chain.
# Choices are carried between steps in query params (vendor_id, property_id, buyer_id);
# nothing is linked together until the final step creates the transaction.
class SalesController < ApplicationController
  STEPS = %w[vendor property buyer chain].freeze
  STEP_LABELS = { "vendor" => "Vendor", "property" => "Property", "buyer" => "Buyer", "chain" => "Chain" }.freeze
  STEP_PARAMS = { "vendor" => :vendor_id, "property" => :property_id, "buyer" => :buyer_id }.freeze
  # Fields of the new client form that an uploaded client PDF can fill in
  CLIENT_FIELDS_FROM_DOCUMENT = %w[first_name last_name email phone onward_purchase].freeze
  # Fields of the new property form that the vendor's client PDF can fill in (their current home address)
  ADDRESS_FIELDS_FROM_DOCUMENT = %w[house_number street second_line_of_address city post_code].freeze

  helper_method :sale_step_params, :sale_carry_params, :sale_step_state, :previous_sale_step

  def new
    authorize :sale, :new?
    @step = current_step
    return unless load_context

    load_client_document

    prepare_step
  end

  def create
    authorize :sale, :create?
    @step = current_step
    return unless load_context

    load_client_document

    send("create_#{@step}")
  end

  private

  def current_step
    STEPS.include?(params[:step]) ? params[:step] : "vendor"
  end

  # Finds the records chosen in earlier steps and checks the ones this step needs are present.
  def load_context
    @vendor = lookup(:vendor_id) { |id| client_scope.find_by(id: id) }
    @property = lookup(:property_id) { |id| @vendor && property_scope.find_by(id: id) }
    @buyer = lookup(:buyer_id) { |id| buyer_scope.find_by(id: id) }
    return false if performed?

    index = STEPS.index(@step)
    if index >= 1 && @vendor.nil?
      redirect_to new_sale_path, alert: "Choose a vendor first."
      false
    elsif index >= 2 && @property.nil?
      redirect_to new_sale_path(step: "property", vendor_id: @vendor.id), alert: "Choose a property first."
      false
    else
      true
    end
  end

  def lookup(key)
    return nil if params[key].blank?

    record = yield(params[key])
    unless record || performed?
      redirect_to new_sale_path, alert: "We couldn't find one of the records you chose. Please start the sale again."
    end
    record
  end

  def client_scope
    policy_scope(InvolvedParty)
  end

  def buyer_scope
    @vendor ? client_scope.where.not(id: @vendor.id) : client_scope
  end

  # The vendor's own (unsold) properties, plus my unsold listings that have no vendor yet.
  def property_scope
    base = Property.where(sold: [false, nil])
    base.where(involved_party_id: @vendor.id).or(base.where(user_id: current_user.id, involved_party_id: nil))
  end

  # Data each step's view needs
  def prepare_step
    case @step
    when "vendor"
      @clients = client_scope.order(:last_name, :first_name)
      # now works with the client details extracted by AI from PDF upload
      @new_party ||= InvolvedParty.new(seller: true, **client_details_from_document)
    when "property"
      @properties = property_scope.order(:street, :house_number)
      # now works with the client property details extracted by AI from PDF upload
      @address_from_document = address_from_document
      @new_property ||= Property.new(**@address_from_document)
    when "buyer"
      @clients = buyer_scope.order(:last_name, :first_name)
      # now works with the client details extracted by AI from PDF upload
      @new_party ||= InvolvedParty.new(buyer: true, **client_details_from_document)
    when "chain"
      @suggested_chains = suggested_chains
      @linkable_sales = linkable_sales.includes(:user, property: :user, chain: { transactions: :property })
                                      .order("properties.street", "properties.house_number")
                                      .limit(200)
    end
  end

  # Details found in an uploaded client PDF (see ClientDocumentsController), to fill in the new client form
  def client_details_from_document
    return {} unless @client_document&.done?

    @client_document.extracted_data.slice(*CLIENT_FIELDS_FROM_DOCUMENT).compact.symbolize_keys
  end

  # The realtor's own client PDF for this step. The property step uses the vendor's PDF,
  # because a seller's current address is usually the property they're selling.
  def load_client_document
    step = @step == "property" ? "vendor" : @step
    @client_document = current_user.client_documents.find_by(id: params[:client_document_id], step: step)
  end

  # The vendor's address from their client PDF, to fill in the new property form
  def address_from_document
    return {} unless @client_document&.done?
    return {} if @client_document.extracted_data["selling"] == false

    @client_document.extracted_data.slice(*ADDRESS_FIELDS_FROM_DOCUMENT).compact.symbolize_keys
  end

  def render_step_error
    prepare_step
    render :new, status: :unprocessable_entity
  end

  def create_vendor
    vendor =
      if params[:involved_party].present?
        build_party(seller: true, onward_purchase: onward_purchase_param || "undecided")
      else
        choose_party(client_scope)
      end
    return unless vendor

    if !params[:involved_party].present? && (plan = onward_purchase_param)
      authorize vendor, :update?
      apply_onward_purchase!(vendor, plan)
    end

    redirect_to new_sale_path(step: "property", vendor_id: vendor.id, client_document_id: @client_document&.id),
                status: :see_other
  end

  def create_property
    if params[:property].present?
      property = Property.new(new_property_params)
      property.user = current_user
      property.involved_party = @vendor
      authorize property, :create?
      unless property.save
        @new_property = property
        return render_step_error
      end
    else
      property = property_scope.find_by(id: params[:existing_id])
      unless property
        @choice_error = "Choose a property from the list, or add a new one."
        return render_step_error
      end
    end

    redirect_to new_sale_path(step: "buyer", vendor_id: @vendor.id, property_id: property.id), status: :see_other
  end

  def create_buyer
    buyer =
      if params[:involved_party].present?
        build_party(buyer: true)
      else
        choose_party(buyer_scope)
      end
    return unless buyer

    redirect_to new_sale_path(step: "chain", vendor_id: @vendor.id, property_id: @property.id, buyer_id: buyer.id),
                status: :see_other
  end

  def create_chain
    nickname = params[:chain_name].to_s.strip.presence
    onward_sale = nil
    if (link_id = params[:chain_id].to_s[/\Alink-(\d+)\z/, 1])
      onward_sale = linkable_sales.find_by(id: link_id)
      unless onward_sale
        @choice_error = "That property already has a buyer. Choose another or start a new chain."
        return render_step_error
      end
      chain = onward_sale.chain
    elsif params[:chain_id].blank? || params[:chain_id] == "new"
      chain = Chain.new(user: current_user, active: true, name: nickname)
      authorize chain, :create?
    else
      chain = policy_scope(Chain).find_by(id: params[:chain_id])
      unless chain
        @choice_error = "That chain no longer exists. Choose another or start a new one."
        return render_step_error
      end
    end

    sale = Transaction.new(user: current_user, property: @property, involved_party: @buyer, chain: chain,
                           legal_stage: "offer_accepted")
    authorize sale, :create?

    ActiveRecord::Base.transaction do
      if onward_sale
        # Recheck under lock so two agents can't both claim the same purchase
        onward_sale.lock!
        if onward_sale.involved_party_id.present?
          onward_sale.errors.add(:base, "#{onward_sale.property.short_address} has just been given a buyer")
          raise ActiveRecord::RecordInvalid, onward_sale
        end

        onward_sale.update!(involved_party: @vendor)
        apply_onward_purchase!(@vendor, "buying")
      end
      # Link the vendor to the property (only ever offered when unassigned or already theirs)
      @property.update_attribute(:involved_party_id, @vendor.id) if @property.involved_party_id.nil?
      @vendor.update_attribute(:seller, true) unless @vendor.seller?
      @buyer.update_attribute(:buyer, true) if @buyer && !@buyer.buyer?
      chain.save! if chain.new_record?
      sale.save!
    end

    # Adding a property that already sits in a chain merges the chains, so read the chain back
    final_chain = sale.reload.chain
    final_chain.update(name: nickname) if nickname && chain.id != final_chain.id && final_chain.name.blank?

    label = final_chain.name.presence || helpers.chain_name(final_chain)
    redirect_to chain_path(final_chain), notice: "Sale created — #{@property.short_address} added to #{label}",
                                         status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    @choice_error = "The sale couldn't be saved: #{e.record.errors.full_messages.to_sentence}"
    render_step_error
  end

  # Creates a client from the inline form; re-renders the step on validation errors.
  def build_party(attrs)
    party = InvolvedParty.new(new_party_params.merge(attrs))
    party.user = current_user
    authorize party, :create?
    return party if party.save

    @new_party = party
    render_step_error
    nil
  end

  def choose_party(scope)
    party = scope.find_by(id: params[:existing_id])
    return party if party

    @choice_error = "Choose a client from the list, or add a new one."
    render_step_error
    nil
  end

  # Saved without full validation so older client records missing contact details don't block the sale
  def apply_onward_purchase!(party, plan)
    party.onward_purchase = plan
    party.seller = true
    party.buyer = true if plan == "buying"
    party.save!(validate: false)
  end

  def onward_purchase_param
    value = params[:onward_purchase].presence || params.dig(:involved_party, :onward_purchase).presence
    value if InvolvedParty::ONWARD_PURCHASE_OPTIONS.key?(value)
  end

  # Chains where the buyer is selling, or the vendor is buying, are the likely links for this sale.
  def suggested_chains
    found = {}
    add = lambda do |scope, reason|
      scope.includes(transactions: :property).distinct.each { |chain| found[chain.id] ||= [chain, reason] }
    end

    add.call(Chain.where(id: Transaction.where(property_id: @property.id).select(:chain_id)),
             "Already includes #{@property.short_address}")
    if @buyer
      buyer_sales = Transaction.joins(:property).where(properties: { involved_party_id: @buyer.id })
      add.call(Chain.where(id: buyer_sales.select(:chain_id)),
               "#{@buyer.full_name} (your buyer) is selling in this chain")
    end
    add.call(Chain.where(id: Transaction.where(involved_party_id: @vendor.id).select(:chain_id)),
             "#{@vendor.full_name} (your vendor) is buying in this chain")
    found.values
  end

  # Pending sales in any agent's chain that still need a buyer: the vendor can be linked in as that buyer.
  def linkable_sales
    Transaction.pending.joins(:property)
               .where(involved_party_id: nil)
               .where.not(property_id: @property.id)
               .where(properties: { sold: [false, nil] })
               .where("properties.involved_party_id IS NULL OR properties.involved_party_id <> ?", @vendor.id)
  end

  def new_party_params
    params.require(:involved_party).permit(:first_name, :last_name, :email, :phone)
  end

  def new_property_params
    params.require(:property).permit(:house_number, :street, :second_line_of_address, :city, :post_code, :photo)
  end

  # Query params for a step's page: ids chosen up to and including that step (so it's preselected)
  def sale_step_params(step)
    keys = STEPS.first(STEPS.index(step) + 1).filter_map { |s| STEP_PARAMS[s] }
    { step: step }.merge(chosen_ids.slice(*keys).compact)
  end

  # Hidden fields a step's forms carry forward: ids chosen before that step
  def sale_carry_params(step)
    chosen_ids.slice(*STEPS.first(STEPS.index(step)).filter_map { |s| STEP_PARAMS[s] }).compact
  end

  def chosen_ids
    { vendor_id: @vendor&.id, property_id: @property&.id, buyer_id: @buyer&.id }
  end

  def sale_step_state(step)
    index = STEPS.index(step)
    current = STEPS.index(@step)
    if index < current then :done
    elsif index == current then :current
    else :upcoming
    end
  end

  def previous_sale_step
    index = STEPS.index(@step)
    index.positive? ? STEPS[index - 1] : nil
  end
end
