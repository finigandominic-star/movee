module PropertiesHelper
  # Sale progress derived from existing data, in order. Each stage is
  # { name:, info:, done: }; the first stage that isn't done is the current one.
  def property_progress_stages(property)
    [
      { name: "Listed", info: "Property has been listed", done: true },
      { name: "Vendor assigned", info: "Assign the vendor (seller) to this property", done: property.involved_party.present? },
      { name: "In a chain", info: "Add this property to a chain via a transaction", done: property.transactions.any? },
      { name: "Transaction complete", info: "Waiting for a transaction to complete", done: property.transactions.any?(&:completed?) },
      { name: "Sold", info: "Mark the property as sold once the sale goes through", done: property.sold? }
    ]
  end

  # square thumbnail of the property's uploaded photo, or a house icon if it has none
  def property_thumbnail(property, size: 56)
    if property.photo.attached?
      image_tag property.photo, alt: property.short_address, class: "rounded object-fit-cover flex-shrink-0", width: size, height: size
    else
      tag.div class: "rounded bg-light text-secondary d-flex align-items-center justify-content-center flex-shrink-0",
              style: "width: #{size}px; height: #{size}px;" do
        tag.i class: "fa-solid fa-house opacity-50"
      end
    end
  end
end
