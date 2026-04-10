# Be sure to restart your server when you modify this file.
#
# Console CSP errors that mention content.js, csHttp.bundle.js, utils.js, or
# "sandbox eval" are almost always from browser extensions or devtools — they
# inject inline <script>/<style> without your page nonce. This app cannot allow
# that without unsafe-inline. Use a private window with extensions disabled to
# verify a clean console for *your* code.
#
# http://fonts.googleapis.com and http://fonts.gstatic.com: some extensions load
# Google Fonts over HTTP; listing those origins avoids spurious font-src/style
# noise. The app uses HTTPS in app/assets/tailwind/application.css.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src      :self
    policy.base_uri         :self
    policy.font_src         :self, :https, :data, 'https://fonts.gstatic.com', 'http://fonts.gstatic.com'
    policy.img_src          :self, :https, :data, :blob
    policy.object_src       :none
    policy.script_src       :self, 'https://cdn.jsdelivr.net'
    policy.script_src_elem  :self, 'https://cdn.jsdelivr.net'
    policy.style_src        :self, 'https://fonts.googleapis.com', 'http://fonts.googleapis.com'
    policy.style_src_elem   :self, 'https://fonts.googleapis.com', 'http://fonts.googleapis.com'
    policy.connect_src      :self
    policy.form_action      :self
    policy.frame_ancestors  :none
  end

  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # script-src-elem / style-src-elem: Hotwire Turbo injects nonce’d <script>/<style> at runtime.
  # style-src / style-src-elem: allow @import of Google Fonts from compiled CSS + nonce’d <link> tags.
  config.content_security_policy_nonce_directives = %w[
    script-src
    script-src-elem
    style-src
    style-src-elem
  ]

  # config.content_security_policy_report_only = true
end
