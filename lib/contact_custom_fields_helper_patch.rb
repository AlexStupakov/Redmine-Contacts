require_dependency 'custom_fields_helper'

module ContactCustomFieldsHelperPatch

  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable

      alias_method_chain :custom_fields_tabs, :contact
    end
  end

  module ClassMethods
  end

  module InstanceMethods

    def custom_fields_tabs_with_contact
      tabs = custom_fields_tabs_without_contact
      unless tabs.collect{ |tab| tab[:name] }.include?('ContactCustomField')
        tabs.push({ :name => 'ContactCustomField',
                    :partial => 'custom_fields/index',
                    :label => :label_contact_plural })
      end
      tabs
    end

  end

end
