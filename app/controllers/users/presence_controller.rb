module Users
  class PresenceController < ApplicationController
    def update
      Current.user&.touch(:last_seen_at)

      head :ok
    end
  end
end
