require 'holidays'

module Holidays
  class Team
    class UnknownTeamMember < StandardError; end

    attr_reader :uk_holidays, :us_holidays

    SIX_MONTHS = 6.months.ago

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
    ).freeze

    def initialize
      setup_us_holidays
      setup_uk_holidays
    end

    def member_holiday?(team_member, date)
      case team_member
      when *UK_GH_USERNAMES
        uk_holidays.include?(date)
      when *US_GH_USERNAMES
        us_holidays.include?(date)
      else
        raise UnknownTeamMember.new(
          "Unknown team member name #{team_member}"
        )
      end
    end

    private

    def setup_us_holidays
      @us_holidays = Set.new(holidays_for_region(:us))
    end

    # Not idea as this requires updates as the years progress but it'll do
    # It will need to add the dept closures in for ever :sadpanda:
    def setup_uk_holidays
      gb_holidays = holidays_for_region(:gb)
      oxford_holidays_2017 = [22,23,24,27,28,29,30,31].map do |day|
        Date.parse("#{day}-12-2017")
      end
      oxford_holidays_2018 = [ Date.parse('02-01-2018') ]
      uk_hols = gb_holidays | oxford_holidays_2017 | oxford_holidays_2018
      @uk_holidays = Set.new(uk_hols)
    end

    def holidays_for_region(region)
      Holidays.between(SIX_MONTHS, Date.today, region, :observed).map do |holiday|
        holiday[:date]
      end
    end
  end
end
