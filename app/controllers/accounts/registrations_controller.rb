module Accounts
  class RegistrationsController < Devise::RegistrationsController
    after_action :set_validation_error_status, only: :update

    private

    def set_validation_error_status
      return unless request.format.html?
      return unless response.status == 200
      return if resource.errors.empty?

      response.status = 422
    end
  end
end
