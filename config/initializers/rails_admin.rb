require Rails.root.join 'lib/rails_admin/config/fields/types/citext'

RailsAdmin.config do |config|

  ### Popular gems integration

  ## == Devise ==
  # config.authenticate_with do
  #   warden.authenticate! scope: :user
  # end
  # config.current_user_method(&:current_user)

  ## == CancanCan ==
  # config.authorize_with :cancancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  config.authorize_with do
    authenticate_or_request_with_http_basic 'Login required' do |username, password|
      expected_user = Rails.application.credentials.dig :admin, :user
      expected_pass = Rails.application.credentials.dig :admin, :password

      ActiveSupport::SecurityUtils.secure_compare(username, expected_user) &&
        ActiveSupport::SecurityUtils.secure_compare(password, expected_pass)
    end
  end

  config.parent_controller = 'AdminController'
end
