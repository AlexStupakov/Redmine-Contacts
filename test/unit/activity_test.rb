require File.expand_path('../../test_helper', __FILE__)

class ActivityTest < ActiveSupport::TestCase

  def setup
    User.current = nil
    @project = Project.find(1)
    @contact = Contact.create(:project => @project,
                   name: 'the contact',
                   email: 'contact@example.com')
  end

  def test_activity_with_contact
    events = find_events(User.anonymous, :project => @project)
    assert_not_nil events

    assert events.include?(@contact)
  end

  def test_global_activity_logged_user_with_contact
    events = find_events(User.find(1), :project => @project)
    assert_not_nil events

    assert events.include?(@contact)
  end

  # contact
  def test_event_group_for_contact
    content = @contact
    assert_equal content, content.event_group
  end

  private

  def find_events(user, options={})
    Redmine::Activity::Fetcher.new(user, options).events(Date.today - 30, Date.today + 1)
  end
end
