require "rails_helper"

feature "User creates a team subscription" do
  background do
    create_team_plan
    sign_in
  end

  scenario "creates a team subscription with a valid credit card" do
    subscribe_with_valid_credit_card

    expect(current_path).to eq after_sign_up_path
    expect(page).
      to have_content(I18n.t("checkout.flashes.success", name: plan.name))
    expect(settings_page).to have_subscription_to(plan.name)
    expect(FakeStripe.customer_plan_quantity).to eq plan.minimum_quantity.to_s
  end

  scenario "sees that the subscription is per month" do
    visit_team_plan_checkout_page

    expect_submit_button_to_contain("per month")
  end

  scenario "sees that the default quantity is 5" do
    visit_team_plan_checkout_page

    expect(field_labeled("Number of team members").value).
      to eq plan.minimum_quantity.to_s
  end

  scenario "creates a team subscription with more members", js: true do
    requested_quantity = "6"

    visit_team_plan_checkout_page

    expect_submit_button_to_contain_default_text

    select requested_quantity, from: "Number of team members"

    expect_submit_button_to_contain("$534 per month")

    fill_out_subscription_form_with VALID_SANDBOX_CREDIT_CARD_NUMBER

    expect(current_path).to eq after_sign_up_path
    expect(FakeStripe.customer_plan_quantity).to eq requested_quantity
  end

  scenario "creates a Stripe subscription with a valid amount off coupon", js: true do
    create_amount_stripe_coupon("5OFF", "once", 500)

    visit_team_plan_checkout_page

    expect_submit_button_to_contain_default_text

    apply_coupon_with_code("5OFF")

    expect_submit_button_to_contain discount_text("262.00", "267.00")

    fill_out_subscription_form_with VALID_SANDBOX_CREDIT_CARD_NUMBER

    expect(current_path).to eq after_sign_up_path # need this check for capybara to wait
    expect(FakeStripe.last_coupon_used).to eq "5OFF"
    expect(FakeStripe.customer_plan_quantity).to eq plan.minimum_quantity.to_s
  end

  scenario "does not see the option to pay with paypal" do
    visit_team_plan_checkout_page
    click_prime_call_to_action_in_header

    expect(page).not_to have_css("#checkout_payment_method_paypal")
  end

  scenario "user without github username sees github username input" do
    current_user.github_username = nil
    current_user.save!

    visit_team_plan_checkout_page

    expect(page).to have_content("GitHub username")
    expect(page).to have_css("input#checkout_github_username")
  end

  scenario "user with github username doesn't see github username input" do
    current_user.github_username = "cpyteltest"
    current_user.save!

    visit_team_plan_checkout_page

    expect(page).not_to have_content("GitHub username")
    expect(page).not_to have_css("input#checkout_github_username")
  end

  scenario "creates a Stripe subscription with a valid amount off coupon", js: true do
    create_amount_stripe_coupon("5OFF", "once", 500)

    visit_team_plan_checkout_page

    expect_submit_button_to_contain_default_text

    apply_coupon_with_code("5OFF")

    expect_submit_button_to_contain discount_text("262.00", "267.00")

    fill_out_subscription_form_with VALID_SANDBOX_CREDIT_CARD_NUMBER

    expect(current_path).to eq after_sign_up_path
    expect(page).to have_content(I18n.t("checkout.flashes.success", name: plan.name))
    expect(FakeStripe.last_coupon_used).to eq "5OFF"
  end

  scenario "tries to subscribe with an invalid coupon", :js => true do
    visit_team_plan_checkout_page

    expect_submit_button_to_contain_default_text

    apply_coupon_with_code("5OFF")

    expect(page).to have_content("The coupon code you supplied is not valid.")
  end

  def subscribe_with_valid_credit_card
    visit_team_plan_checkout_page
    fill_out_subscription_form_with VALID_SANDBOX_CREDIT_CARD_NUMBER
  end

  def subscribe_with_invalid_credit_card
    visit_team_plan_checkout_page
    FakeStripe.failure = true
    fill_out_subscription_form_with "bad cc number"
  end

  def plan
    TeamPlan.first
  end

  def create_team_plan
    create(:team_plan)
  end

  def apply_coupon_with_code(code)
    click_link "Have a coupon code?"
    fill_in "Code", with: code
    click_button "Apply Coupon"
  end

  def discount_text(new, original)
    I18n.t(
      "subscriptions.discount.once",
      final_price: new,
      full_price: original,
    )
  end

  def after_sign_up_path
    edit_team_path
  end

  def expect_to_see_the_current_plan(plan)
    expect(page).to have_css(
      ".subscription p strong",
      text: plan.name
    )
  end

  def expect_submit_button_to_contain_default_text
    expect_submit_button_to_contain("$267 per month")
  end

  def visit_team_plan_checkout_page
    visit new_checkout_path(plan)
  end
end