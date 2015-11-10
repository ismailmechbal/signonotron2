require 'test_helper'

class TwoStepVerificationControllerTest < ActionController::TestCase
  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
    @controller = Devise::TwoStepVerificationController.new

    @user = create(:user)
    sign_in @user
  end

  context 'after the 2SV hard go live date' do
    context 'for admin accounts' do
      setup do
        sign_out @user

        @admin = create(:admin_user)
        sign_in @admin
      end

      should 'not permit deferral' do
        travel_to User::TWO_STEP_GO_LIVE_DATE do
          put :defer

          assert_redirected_to root_path
        end
      end
    end
  end

  context 'when unauthenticated' do
    setup { sign_out @user }

    should 'redirect to login upon attempted deferral' do
      put :defer

      assert_redirected_to new_user_session_path
    end

    should 'redirect to login upon attempted prompt' do
      get :prompt

      assert_redirected_to new_user_session_path
    end
  end

  context "otp_secret_key_uri" do
    setup do
      @secret = ROTP::Base32.random_base32
      ROTP::Base32.stubs(random_base32: @secret)

      get :show
    end

    should "include the secret key uppercased" do
      assert_match %r{#{@secret.upcase}}, @controller.otp_secret_key_uri
    end

    should "include the environment titleised" do
      assert_match %r{issuer=Development%20GOV.UK%20Signon}, @controller.otp_secret_key_uri
    end

    context "in production" do
      setup do
        @old_instance_name = Rails.application.config.instance_name
        Rails.application.config.instance_name = nil
      end

      teardown do
        Rails.application.config.instance_name = @old_instance_name
      end

      should "not include the environment name" do
        assert_match %r{issuer=GOV.UK%20Signon}, @controller.otp_secret_key_uri
      end
    end

    should "include the user's email" do
      assert_match %r{#{@user.email}}, @controller.otp_secret_key_uri
    end
  end
end
