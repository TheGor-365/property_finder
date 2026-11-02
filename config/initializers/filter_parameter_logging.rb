# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  :password, :password_confirmation, :current_password, :reset_password_token,
  :token, :secret, :secret_key_base, :authorization, :smtp_password,
  :email, :message, :first_name, :last_name, :telephone
]
