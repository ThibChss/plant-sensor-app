class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  default_scope { order(created_at: :asc) }

  def dom_id
    ActionView::RecordIdentifier.dom_id(self)
  end
end
