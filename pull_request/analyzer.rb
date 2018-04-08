require_relative '../team/work_days'

module PullRequest
  class Analyzer
    attr_reader :client, :repo, :pr, :team_work_days

    def initialize(client:, repo:, pr:)
      @client = client
      @repo = repo
      @pr = pr
      @team_work_days = Team::WorkDays.new
    end

    def process
      return if missing_review_request?

      analyzed_pr = Fields.hash_with_defaults
      analyzed_pr[:repo] = pr.base.repo.name
      analyzed_pr[:href] = pr.html_url
      analyzed_pr[:number] = pr.number
      analyzed_pr[:user_id] = pr.user.id
      analyzed_pr[:user_login] = pr.user.login
      analyzed_pr[:created_at] = pr.created_at
      analyzed_pr[:closed_at] = pr.closed_at
      analyzed_pr[:merged_at] = pr.merged_at

      if has_reviews?
        analyzed_pr[:days_to_first_review] = days_to_first_review
        analyzed_pr[:time_to_first_review] = time_to_first_review
      end

      if approved?
        analyzed_pr[:time_to_approval] = time_to_approval
      end

      if merged?
        analyzed_pr[:time_to_merge] = time_to_merged
      end

      if merged? && approved?
        analyzed_pr[:approval_to_merge] = time_from_approval_to_merge
      end

      analyzed_pr
    end

    private

    def review_requests
      @review_requests ||= client.pull_request_review_requests(repo, pr.number)
    end

    def reviews
      @reviews ||= client.pull_request_reviews(repo, pr.number)
    end

    def reviewer_reviews
      @reviewer_reviews ||= reviews.select do |review|
        not_hound = review.user.login != "houndci-bot"
        not_issuer = review.user.id != pr.user.id
        not_hound && not_issuer
      end
    end

    # !!! Questionable decision to skip PR's here !!!
    # revisit this skip decision if my assumptions are wrong (highly likely)
    # when can a PR not have a review request...old ones?
    # for now skip PRs without a requested reviewer or a review
    # most likely these are open but sitting around
    def missing_review_request?
      reviewer_reviews.empty? && review_requests[:users].empty?
    end

    def approved_reviews
      @approved_reviews ||= reviews.select do |review|
        not_issuer = review.user.id != pr.user.id
        not_issuer && review.state == "APPROVED"
      end
    end

    def issue_events
      @issue_events ||= client.issue_events(repo, pr.number)
    end

    def first_review_request_time
      first_review_request = issue_events.find do |issue_event|
        issue_event.event == "review_requested"
      end

      first_review_request.created_at if first_review_request
    end

    def has_reviews?
      !reviewer_reviews.empty?
    end

    def first_review
      @first_review ||= reviewer_reviews.first
    end

    def first_reviewer_login
      @first_reviewer_login ||= first_review[:user][:login]
    end

    def max_seconds_between_dates(dates)
      if dates.length == 1
        PullRequest::Processor::ONE_DAY
      else
        first_date, last_date = dates.sort.values_at(0,-1)
        ((last_date - first_date) * PullRequest::Processor::ONE_DAY).to_i
      end
    end

    def seconds_between_times(end_time, start_time)
      (end_time - start_time).to_i
    end

    def working_seconds_between_times(start_time, end_time)
      seconds_between_times = seconds_between_times(end_time, start_time)
      non_work_days = []
      (start_time.to_date..end_time.to_date).each do |date|
        begin
          day_off = team_work_days.non_work_day?(first_reviewer_login, date)
        rescue Team::Members::UnknownTeamMember => error
          day_off = false
          puts error.message
        ensure
          non_work_days << date if day_off
        end
      end

      total_days_off_in_seconds = 0
      if non_work_days.length > 0
        total_days_off_in_seconds = max_seconds_between_dates(non_work_days)
      end

      seconds_between_times - total_days_off_in_seconds
    end

    def time_to_first_review
      return @time_to_first_review if @time_to_first_review
      first_review_time = first_review.submitted_at
      seconds_till_review = working_seconds_between_times(
        proxy_for_ready_time,
        first_review_time
      )
      @time_to_first_review = if seconds_till_review < 0
        working_seconds_between_times(pr.created_at, first_review_time)
      else
        seconds_till_review
      end
    end

    def days_to_first_review
      (time_to_first_review / 60.0 / 60.0 / 24.0).round(1)
    end

    def approved?
      @approved ||= !approved_reviews.empty?
    end

    def time_to_approval
      approval_time = approved_reviews.first.submitted_at
      seconds_between_times(approval_time, proxy_for_ready_time)
    end

    def merged?
      !!pr.merged_at
    end

    def time_to_merged
      seconds_between_times(pr.merged_at, proxy_for_ready_time)
    end

    def time_from_approval_to_merge
      approved_at = approved_reviews.first.submitted_at
      seconds_between_times(pr.merged_at, approved_at)
    end

    def proxy_for_ready_time
      @proxy_for_ready_time ||= first_review_request_time || pr.created_at
    end
  end
end
