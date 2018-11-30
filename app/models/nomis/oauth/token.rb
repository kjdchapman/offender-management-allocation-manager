module Nomis
  module Oauth
    class Token
      attr_reader :access_token

      def initialize(access_token)
        @access_token = access_token
      end

      def expired?
        JWT.decode(
          @access_token,
          OpenSSL::PKey::RSA.new(Rails.configuration.nomis_oauth_public_key),
          true,
          algorithm: 'RS256'
        )
        false
      rescue JWT::ExpiredSignature => e
        Raven.capture_exception(e)
        true
      end
    end
  end
end
