# frozen_string_literal: true

module Components
  class Base < Phlex::HTML
    # Include any helpers you want to be available across all components
    include Phlex::Rails::Helpers::Routes

    private

    def t(key, **options)
      view_context.t(key, **options)
    end

    def icon(name, **options)
      view_context.icon(name, **options)
    end

    def cache(*args, &)
      view_context.cache(*args, &)
    end
  end
end
