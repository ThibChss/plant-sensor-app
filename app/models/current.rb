class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :page
  attribute :previous_page

  delegate :user, to: :session, allow_nil: true
end
