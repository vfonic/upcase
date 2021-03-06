require "selenium/webdriver"

Capybara.register_driver :custom_headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: {
      args: %w(
        headless
        disable-gpu
        no-sandbox
        window-size=1920,1080
        --enable-features=NetworkService,NetworkServiceInProcess
      ),
    },
  )

  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    desired_capabilities: capabilities
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :custom_headless_chrome
  end

  config.before(:each, type: :system, visible_js: true) do
    driven_by :selenium_chrome
  end
end

Capybara.javascript_driver = :custom_headless_chrome
