class ContactQuery < Query

  self.queried_class = Contact

  self.available_columns = [
    QueryColumn.new(:id, :sortable => "#{Contact.table_name}.id", :default_order => 'desc', :caption => '#'),
    QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true, :frozen => true),
    QueryColumn.new(:name, :sortable => "#{Contact.table_name}.name", :frozen => true),
    QueryColumn.new(:country, :sortable => "#{Contact.table_name}.country", :frozen => true),
    QueryColumn.new(:city, :sortable => "#{Contact.table_name}.city", :frozen => true),
    QueryColumn.new(:street, :sortable => "#{Contact.table_name}.street", :frozen => true),
    QueryColumn.new(:house, :sortable => "#{Contact.table_name}.house", :frozen => true),
    QueryColumn.new(:phone, :sortable => "#{Contact.table_name}.phone", :frozen => true),
    QueryColumn.new(:zip, :sortable => "#{Contact.table_name}.zip", :frozen => true),
    QueryColumn.new(:email, :sortable => "#{Contact.table_name}.email", :frozen => true),
    QueryColumn.new(:updated_at, :sortable => "#{Contact.table_name}.updated_at", :default_order => 'desc', :frozen => true),
    QueryColumn.new(:created_at, :sortable => "#{Contact.table_name}.created_at", :default_order => 'desc', :frozen => true)
  ]

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= {}
  end


  # def build_from_params(params, defaults={})
  #   super
  #   self.draw_relations = params[:draw_relations] || (params[:query] && params[:query][:draw_relations]) || options[:draw_relations]
  #   self.draw_progress_line = params[:draw_progress_line] || (params[:query] && params[:query][:draw_progress_line]) || options[:draw_progress_line]
  #   self
  # end

  def initialize_available_filters
    add_available_filter("project_id",
      :type => :list, :values => lambda { project_values }
    ) if project.nil?

    add_available_filter 'name', :type => :text
    add_available_filter 'country', :type => :text
    add_available_filter 'city', :type => :text
    add_available_filter 'street', :type => :text
    add_available_filter 'house', :type => :text
    add_available_filter 'phone', :type => :text
    add_available_filter 'zip', :type => :text
    add_available_filter 'email', :type => :text
    add_available_filter 'updated_at', :type => :date
    add_available_filter 'created_at', :type => :date

    # add_available_filter("project.status",
    #   :type => :list,
    #   :name => l(:label_attribute_of_project, :name => l(:field_status)),
    #   :values => lambda { project_statuses_values }
    # ) if project.nil? || !project.leaf?

    # add_custom_fields_filters(contact_custom_fields)
    # add_associations_custom_fields_filters :project
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    # @available_columns += contact_custom_fields.visible.collect {|cf| QueryCustomFieldColumn.new(cf) }

    @available_columns
  end

  def default_columns_names
    @default_columns_names ||= begin
      default_columns = %i(name country city street house phone zip email updated_at created_at)
      project.present? ? default_columns : [:project] | default_columns
    end
  end

  def default_sort_criteria
    [['id', 'desc']]
  end

  def base_scope
    Contact.joins(:project).where(statement)
  end

  # Returns the Contact count
  def contact_count
    base_scope.count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the contacts
  # Valid options are :order, :offset, :limit, :include, :conditions
  def contacts(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = Contact.
      joins(:project).
      where(statement).
      includes(([:project] + (options[:include] || [])).uniq).
      where(options[:conditions]).
      order(order_option).
      joins(joins_for_order_statement(order_option.join(','))).
      limit(options[:limit]).
      offset(options[:offset])

    if has_custom_field_column?
      scope = scope.preload(:custom_values)
    end

    contacts = scope.to_a
    contacts
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the contacts ids
  def contact_ids(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    Contact.
      joins(:project).
      where(statement).
      includes(([:project] + (options[:include] || [])).uniq).
      references(([:project] + (options[:include] || [])).uniq).
      where(options[:conditions]).
      order(order_option).
      joins(joins_for_order_statement(order_option.join(','))).
      limit(options[:limit]).
      offset(options[:offset]).
      pluck(:id)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the journals
  # Valid options are :order, :offset, :limit
  def journals(options={})
    Journal.visible.
      joins(:contact => [:project]).
      where(statement).
      order(options[:order]).
      limit(options[:limit]).
      offset(options[:offset]).
      preload(:details, :user, {:contact => [:project]}).
      to_a
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

end
