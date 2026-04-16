module Users
  class PushSubscriptionsController < ApplicationController
    before_action :set_push_subscriptions

    def create
      return head :unauthorized unless user.push_notifications_enabled?

      if (subscription = @push_subscription.find_by(push_subscription_params))
        subscription.touch
      else
        @push_subscription.create!(push_subscription_params.merge(user_agent: request.user_agent))
      end

      head :ok
    end

    private

    def set_push_subscriptions
      @push_subscription = user.push_subscriptions
    end

    def push_subscription_params
      params.require(:push_subscription).permit(:endpoint, :p256dh_key, :auth_key, :pwa)
    end

    def user
      @user ||= Current.user
    end
  end
end
