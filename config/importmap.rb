# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "i18n-js", to: "https://cdn.jsdelivr.net/npm/i18n-js@4.5.3/+esm"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/sensor_setup", under: "sensor_setup"
# config/importmap.rb
pin "chart.js", to: "https://esm.sh/chart.js@4.5.1"
pin "chartjs-adapter-date-fns", to: "https://esm.sh/chartjs-adapter-date-fns@3.0.0"
pin "date-fns", to: "https://esm.sh/date-fns@3.6.0"
