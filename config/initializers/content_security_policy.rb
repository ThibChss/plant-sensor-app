# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src      :self
    policy.base_uri         :self
    policy.font_src         :self, :https, :data
    policy.img_src          :self, :https, :data, :blob
    policy.object_src       :none
    policy.script_src       :self
    policy.style_src        :self
    policy.connect_src      :self
    policy.form_action      :self
    policy.frame_ancestors  :none
  end

  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]

  # config.content_security_policy_report_only = true
end
