module VCAP::CloudController
  class PackageModel < Sequel::Model(:packages)
    PENDING_STATE  = 'PROCESSING_UPLOAD'
    READY_STATE    = 'READY'
    FAILED_STATE   = 'FAILED'
    CREATED_STATE  = 'AWAITING_UPLOAD'
    PACKAGE_STATES = [CREATED_STATE, PENDING_STATE, READY_STATE, FAILED_STATE].map(&:freeze).freeze

    one_to_one :app, class: 'VCAP::CloudController::AppModel', key: :guid, primary_key: :app_guid

    def validate
      validates_includes PACKAGE_STATES, :state, allow_missing: true
    end

    def self.user_visible(user)
      app_guids = AppModel.user_visible(user).map { |app| app.guid }
      dataset.where(app_guid: app_guids)
    end
  end
end
