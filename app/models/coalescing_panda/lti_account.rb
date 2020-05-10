module CoalescingPanda
  class LtiAccount < ActiveRecord::Base
    validates :name, :key, uniqueness: true
    validates :name, :key, :secret, presence: true
    has_many :coalescing_panda_lti_nonces,
             :foreign_key => :coalescing_panda_lti_account_id,
             :class_name => 'CoalescingPanda::LtiNonce'

    attr_accessible :name, :key, :secret, :oauth2_client_id, :oauth2_client_key, :settings, :coalescing_panda_lti_nonces
    serialize :settings

    def validate_nonce(nonce, timestamp)
      cleanup_nonce
      if timestamp > 15.minutes.ago
        coalescing_panda_lti_nonces.create(nonce: nonce, timestamp: timestamp).persisted?
      end
    end

    private

    def cleanup_nonce
      coalescing_panda_lti_nonces.where('timestamp > ?', 15.minutes.ago).delete_all
    end

  end
end
