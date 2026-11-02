module Accounts
  class RegistrationsController < Devise::RegistrationsController
    after_action :set_validation_error_status, only: :update

    # Never orphan existing property listings or their enquiries.
    # An account with no listings can still be deleted through Devise.
    def destroy
      if resource.properties.exists?
        redirect_to edit_account_registration_path,
          alert: "Remove your listings before deleting your account. Listings with enquiries require administrator assistance."
        return
      end

      super
    end

    private

    def set_validation_error_status
      return unless request.format.html?
      return unless response.status == 200
      return if resource.errors.empty?

      response.status = 422
    end
  end
end
