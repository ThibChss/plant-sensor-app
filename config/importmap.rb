# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "i18n-js", to: "https://cdn.jsdelivr.net/npm/i18n-js@4.5.3/+esm"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/sensor_setup", under: "sensor_setup"
