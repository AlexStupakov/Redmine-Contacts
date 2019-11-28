class Contact < ActiveRecord::Base
  include Redmine::SafeAttributes

  has_many :journals, as: :journalized, dependent: :destroy, inverse_of: :journalized
  belongs_to :project
  belongs_to :author, class_name: 'User'

  acts_as_attachable  :delete_permission => :manage_files,
                      :after_add => :attachment_added,
                      :after_remove => :attachment_removed

  acts_as_searchable columns: %w(contacts.name country city email),
                     scope: joins(:project)

  acts_as_event title: Proc.new { |o| "#{o.name} #{o.email}" },
                description: :name,
                url: Proc.new { |o| { controller: 'contacts', action: 'show', id: o.id }}

  acts_as_activity_provider scope: joins(:project),
                            permission: nil,
                            author_key: :author_id



  attr_accessor :deleted_attachment_ids
  attr_reader :current_journal
  delegate :notes, :notes=, :private_notes, :private_notes=, :to => :current_journal, :allow_nil => true

  after_save :delete_selected_attachments, :create_journal

  def init_journal(user, notes = "")
    @current_journal ||= Journal.new(:journalized => self, :user => user, :notes => notes)
  end

  # Returns the current journal or nil if it's not initialized
  def current_journal
    @current_journal
  end

  # Clears the current journal
  def clear_journal
    @current_journal = nil
  end

  # Returns the names of attributes that are journalized when updating the issue
  def journalized_attribute_names
    names = Contact.column_names - %w(id created_on updated_on)
    names
  end

  # Returns the id of the last journal or nil
  def last_journal_id
    if new_record?
      nil
    else
      journals.maximum(:id)
    end
  end

  # Returns a scope for journals that have an id greater than journal_id
  def journals_after(journal_id)
    scope = journals.reorder("#{Journal.table_name}.id ASC")
    if journal_id.present?
      scope = scope.where("#{Journal.table_name}.id > ?", journal_id.to_i)
    end
    scope
  end

  # Returns the journals that are visible to user with their index
  # Used to display the issue history
  def visible_journals_with_index(user=User.current)
    result = journals.
      preload(:details).
      preload(user: :email_address).
      reorder(:created_on, :id).to_a

    result.each_with_index {|j,i| j.indice = i+1}

    unless user.allowed_to?(:view_private_notes, project)
      result.select! do |journal|
        !journal.private_notes? || journal.user == user
      end
    end
    Journal.preload_journals_details_custom_fields(result)
    result.select! {|journal| journal.notes? || journal.visible_details.any?}
    result
  end

  def custom_field_values
    []
  end

  def notified_users
    []
  end

  def notified_watchers
    []
  end

  # Saves the changes in a Journal
  # Called after_save
  def create_journal
    if current_journal
      current_journal.save
    end
  end

  def deleted_attachment_ids
    Array(@deleted_attachment_ids).map(&:to_i)
  end

  safe_attributes 'deleted_attachment_ids',
                  :if => lambda {|contact, user| contact.attachments_deletable?(user)}


  def delete_selected_attachments
    if deleted_attachment_ids.present?
      objects = attachments.where(id: deleted_attachment_ids.map(&:to_i))
      attachments.delete(objects)
    end
  end

  # Callback on file attachment
  def attachment_added(attachment)
    if current_journal && !attachment.new_record?
      current_journal.journalize_attachment(attachment, :added)
    end
  end

  # Callback on attachment deletion
  def attachment_removed(attachment)
    if current_journal && !attachment.new_record?
      current_journal.journalize_attachment(attachment, :removed)
      current_journal.save
    end
  end

  # Returns true if user or current user is allowed to edit the issue
  def attributes_editable?(user=User.current)
    user_tracker_permission?(user, :edit_contacts)
  end

  # Overrides Redmine::Acts::Attachable::InstanceMethods#attachments_editable?
  def attachments_editable?(user=User.current)
    attributes_editable?(user)
  end

  private

  def user_tracker_permission?(user, permission)
    if project && !project.active?
      perm = Redmine::AccessControl.permission(permission)
      return false unless perm && perm.read?
    end

    if user.admin?
      true
    else
      roles = user.roles_for_project(project).select {|r| r.has_permission?(permission)}
      roles.any? {|r| r.permissions_all_trackers?(permission) || r.permissions_tracker_ids?(permission, tracker_id)}
    end
  end
end
