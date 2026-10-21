# Receives a client PDF from a "Fill from PDF" box (sales stepper, new client or new property page),
#   reads its text and starts finding the client's details.
# The PDF itself is not kept: only its text is saved (see ClientDocument).

# status: :see_other (HTTP 303) is the correct status for "after a form submission, go to this page".
#   Turbo needs it to follow redirects after a POST, which is why your SalesController uses it too.
class ClientDocumentsController < ApplicationController
  MAX_FILE_SIZE = 5.megabytes

  def create
    # asks Pundit "may this user create a client document?", which runs ClientDocumentPolicy#create?
    authorize ClientDocument
    # for the uploaded file: Rails gives it to us as an object with:
    # original_filename: the name on the realtor's computer; content_type: what kind of file the browser says
    # it is (application/pdf for PDFs); size: the size in bytes; tempfile: a temporary copy on the server,
    # which disappears after the request
    file = params[:file]

    error = upload_error(file)
    return redirect_to(back_path, alert: error, status: :see_other) if error

    # save the document as the realtor's own, using the has_many from the model
    document = current_user.client_documents.create!(
      step: step,
      filename: file.original_filename,
      byte_size: file.size,
      # call on the dfTextExtractor class to read the text here, because the job can't reach the file later
      content: PdfTextExtractor.call(file.tempfile))
    ExtractClientDetailsJob.perform_later(document)

    redirect_to back_path(client_document_id: document.id), status: :see_other
  # a scanned PDF, a broken file or too many pages → the realtor goes back to the step with the error message
  rescue PdfTextExtractor::Error => e
    redirect_to back_path, alert: e.message, status: :see_other
  end

  private

  def step
    # only allow vendor or buyer. Anything else falls back to vendor, so nobody can save a nonsense step.
    # Where the PDF was uploaded (see ClientDocument::STEPS); anything unknown falls back to the vendor step
    ClientDocument::STEPS.include?(params[:step]) ? params[:step] : "vendor"
  end

  # Back to the page the PDF was uploaded on; in the stepper, keeping the choices made in earlier steps
  def back_path(extra = {})
    case step
    when "client" then new_involved_party_path(extra)
    when "property" then new_property_path(extra)
    else
      earlier_choices = { vendor_id: params[:vendor_id], property_id: params[:property_id] }.compact_blank
      new_sale_path(step: step, **earlier_choices, **extra)
    end
  end

  def upload_error(file)
    if file.blank?
      "Choose a PDF file first."
    elsif file.content_type != "application/pdf"
      "Please choose a PDF file."
    elsif file.size > MAX_FILE_SIZE
      "This PDF is too big. The limit is 5 MB."
    end
  end
end
