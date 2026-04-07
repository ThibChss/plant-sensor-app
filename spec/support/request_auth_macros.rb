module RequestAuthMacros
  def sign_in_as(user)
    post session_path, params: {
      email_address: user.email_address,
      password: user.password
    }
  end

  def sign_out
    delete session_path
  end

  module GroupMethods
    def with_user_signed_in(method = :persisted)
      case method
      when :persisted
        let(:user) { create(:user) }
      when :build
        let(:user) { build(:user) }
      when :persisted_forced
        let_it_be(:user) { create(:user) }
      else
        raise ArgumentError, "Invalid method: #{method}"
      end

      before do
        sign_in_as(user)
      end
    end

    def with_user_signed_out
      before do
        sign_out
      end
    end
  end
end

RSpec.configure do |config|
  config.include RequestAuthMacros, type: :request
  config.extend RequestAuthMacros::GroupMethods, type: :request
end
