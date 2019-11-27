Redmine::Plugin.register :redmine_contacts do
  name 'Redmine Contacts plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end

Redmine::Search.map do |search|
  search.register :contacts
end

Redmine::MenuManager.map :application_menu do |menu|
  menu.push(
    :contacts,
    { controller: 'contacts', action: 'index' },
    caption: 'Contacts')
end

