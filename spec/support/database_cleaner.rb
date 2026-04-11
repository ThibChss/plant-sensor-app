require 'database_cleaner/active_record'

# Database Cleaner owns DB state so examples (and files) do not leak rows when
# anything commits, uses threads, or uses before(:all) / let_it_be.
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do |example|
    DatabaseCleaner.strategy =
      if example.metadata[:js] || example.metadata[:truncation]
        :truncation
      else
        :transaction
      end
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
