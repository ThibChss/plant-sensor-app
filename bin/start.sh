#!/bin/bash
set -e

bundle exec rails runner "load Rails.root.join('db/queue_schema.rb') unless ActiveRecord::Base.connection.table_exists?('solid_queue_jobs')"
bundle exec rails runner "load Rails.root.join('db/cable_schema.rb') unless ActiveRecord::Base.connection.table_exists?('solid_cable_messages')"
bundle exec rake db:migrate
bundle exec bin/rails solid_queue:start &
bundle exec bin/rails server -b 0.0.0.0 -p ${PORT:-3000} -e $RAILS_ENV
