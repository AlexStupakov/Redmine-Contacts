module RedmineContactsJournalPatch
  def self.included(base)
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      belongs_to :contact, :foreign_key => :journalized_id
    end
  end

  module InstanceMethods
  end
end

Journal.send(:include, RedmineContactsJournalPatch)
