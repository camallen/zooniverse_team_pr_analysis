# https://github.com/bokmann/business_time/blob/master/README.rdoc
#
# Attempt to use Business Time Gem for more accurate time handling
# Leaving for now but something to revisit with the PR time diffs:
# e.g. proxy_for_ready_time.business_time_until(approval_time)

# BusinessTime::Config.beginning_of_workday = "8:30 am"
# BusinessTime::Config.end_of_workday = "5:30 pm"

# do not use setup_holidays at the moment - see holidays/team.rb
#
# require 'holidays'
#
# Holidays.between(6.months.ago, Date.today, %i(us gb), :observed).map do |holiday|
#   BusinessTime::Config.holidays << holiday[:date]
#   # Implement long weekends if they apply to the region, eg:
#   if !holiday[:date].weekday?
#     BusinessTime::Config.holidays << holiday[:date].next_week
#   end
# end
#
# oxford_holidays_2017 = [22,23,24,27,28,29,30,31].map do |day|
#   Date.parse("#{day}-12-2017")
# end
# oxford_holidays_2018 = [ Date.parse('02-01-2018') ]
# oxford_holidays = oxford_holidays_2017 | oxford_holidays_2018
# BusinessTime::Config.holidays << oxford_holidays
