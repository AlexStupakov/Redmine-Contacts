class ContactsController < ApplicationController
  before_action :set_contact, only: [:show, :edit, :update, :destroy]

  helper :journals
  helper :projects
  helper :custom_fields
  helper :attachments
  helper :queries
  include QueriesHelper

  def index
    use_session = !request.format.csv?
    retrieve_query(ContactQuery, use_session)
    if @query.valid?
      respond_to do |format|
        format.html {
          @contact_count = @query.contact_count
          @contact_pages = Paginator.new @contact_count, per_page_option, params['page']
          @contacts = @query.contacts(:offset => @contact_pages.offset, :limit => @contact_pages.per_page)
          render :layout => !request.xhr?
        }
      end
    else
      respond_to do |format|
        format.html { render :layout => !request.xhr? }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def show
  end

  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)
    @contact.save_attachments(params[:attachments] || (params[:contact] && params[:contact][:uploads]))

    if @contact.save
      redirect_to @contact, notice: 'Contact was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    @contact.init_journal(User.current)
    @contact.safe_attributes = params[:contact]
    @contact.save_attachments(params[:attachments].except(:dummy) ||
                                (params[:contact] && params[:contact][:uploads]))

    if @contact.update(contact_params)
      render_attachment_warning_if_needed(@contact)
      flash[:notice] = l(:notice_successful_update) unless @contact.current_journal.new_record?

      redirect_to @contact
    else
      render :edit
    end
  end

  def destroy
    @contact.destroy
    redirect_to contacts_url, notice: 'Contact was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_contact
      @contact = Contact.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def contact_params
      params.require(:contact).permit(:project_id, :name, :country, :city, :street, :house, :phone, :zip, :email)
    end
end
