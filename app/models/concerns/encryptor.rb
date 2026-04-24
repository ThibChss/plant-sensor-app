module Encryptor
  extend ActiveSupport::Concern

  ERRORS_RESCUED = [
    ActiveSupport::MessageEncryptor::InvalidMessage,
    ActiveSupport::MessageVerifier::InvalidSignature,
    JSON::ParserError
  ].freeze

  private_constant :ERRORS_RESCUED

  class_methods do
    def generate_encrypted_token(purpose: nil, **values)
      encryptor.encrypt_and_sign(values.to_json, purpose:)
    end

    def decrypt_encrypted_token(encrypted_value, purpose: nil)
      decrypted_result = encryptor.decrypt_and_verify(encrypted_value, purpose:)
      return nil if decrypted_result.nil?

      JSON.parse(decrypted_result)
    rescue *ERRORS_RESCUED
      nil
    end

    private

    def encryptor
      ActiveSupport::MessageEncryptor.new(encryptor_key)
    end

    def encryptor_key
      Rails.application.key_generator.generate_key(
        "#{name.underscore}/encryptor",
        ActiveSupport::MessageEncryptor.key_len
      )
    end
  end
end
