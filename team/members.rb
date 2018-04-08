require 'holidays'

module Team
  class Members
    class UnknownTeamMember < StandardError; end

    UK_GH_USERNAMES = %w(
      camallen
      marten
      eatyourgreens
      simoneduca
      rogerhutchings
      CKrawczyk
      mrniaboc
      astopy
      shaunanoordin
      tingard
    ).freeze

    US_GH_USERNAMES = %w(
      srallen
      wgranger
      mcbouslog
      simensta
      jelliotartz
      amyrebecca
      beckyrother
      vrooje
      zwolf
      hughdickinson
      snblickhan
      parrish
    ).freeze

    def country(team_member)
      case team_member
      when *UK_GH_USERNAMES
        :uk
      when *US_GH_USERNAMES
        :us
      else
        raise UnknownTeamMember.new(
          "Unknown team member name #{team_member}"
        )
      end
    end
  end
end
