require 'holidays'
require_relative 'members'

module Team
  class WorkDays
    class UnknownCountry < StandardError; end

    attr_reader :uk_holidays, :us_holidays, :team_members

    def initialize(team_members=Team::Members.new)
      setup_us_holidays
      setup_uk_holidays
      @team_members = team_members
    end

    def non_work_day?(team_member, date)
      weekend?(date) || team_member_holiday?(team_member, date)
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
      Holidays.between(6.months.ago, Date.today, region, :observed).map do |holiday|
        holiday[:date]
      end
    end

    def weekend?(date)
      date.saturday? || date.sunday?
    end

    def team_member_holiday?(team_member, date)
      case team_members.country(team_member)
      when :uk
        uk_holidays.include?(date)
      when :us
        us_holidays.include?(date)
      else
        raise UnknownCountry.new("Unknown country for member: #{team_member}")
      end
    end
  end
end
