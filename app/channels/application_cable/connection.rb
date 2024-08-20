module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private
      def find_verified_user
        if session = find_session_by_cookie
          session.user
        else
          reject_unauthorized_connection
        end
      end

      def find_session_by_cookie
        if token = cookies.signed[:session_token]
          Session.find_signed(token)
        end
      end
  end
end
