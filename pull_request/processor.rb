require 'octokit'
# require_relative '../octokit_extension/add_retries'
require_relative 'analyzer'

module PullRequest
  class Processor
    attr_reader :client, :org_prefix

    STARTS_WITH_WIP = /\A.*wip.*/i
    USER_IS_BOT = /\Adependabot/i
    ONE_DAY = 24 * 60 * 60
    SIX_MONTHS = ONE_DAY * 31 * 6
    REPORT_REPOS = %w(
      panoptes
      Panoptes-Front-End
      talk-api
      caesar
      education-api
    )

    # # create a oauth token for use to avoid mfa issues
    # def self.create_oauth_token(login:, password:, note:, otp: nil)
    #   client = Octokit::Client.new(login: login, password: password)
    #   oauth_token = client.create_authorization(
    #     scopes: ["user"],
    #     note: note,
    #     headers: { "X-GitHub-OTP" => otp }
    #   )
    # end

    def initialize(token:, org_prefix: "zooniverse")
      @client = Octokit::Client.new(access_token: token)
      @org_prefix = org_prefix
    end

    def fetch_repo_prs(repo)
      # http://www.rubydoc.info/github/pengwynn/octokit/Octokit/Client/PullRequests#pull_requests-instance_method
      client.pull_requests(repo, state: 'all')

      # store the gh pr requests for all pages
      repo_pull_requests = []

      # deal with busted paging in octokit
      # https://github.com/octokit/octokit.rb/issues/732#issuecomment-237794222
      puts "Requesting all pull requests from #{repo}"
      last_response = client.last_response
      while true
        next_page_gh_pull_requests = last_response.data

        next_page = last_response.rels[:next]
        break unless next_page

        pr = next_page_gh_pull_requests.first
        # stop if we've gone back in time far enough
        if pr.created_at <= Time.now.utc - SIX_MONTHS
          break
        end

        repo_pull_requests.concat(next_page_gh_pull_requests)

        # manual page handling - load the next page of data and loop
        last_response = next_page.get
      end

      repo_pull_requests
    end

    def analyze_all_repo_pull_requests
      extracted_pull_requests = []

      # %w( panoptes ).each do |repo_suffix|
      REPORT_REPOS.each do |repo_suffix|
        repo = "#{org_prefix}/#{repo_suffix}"

        repo_prs = fetch_repo_prs(repo)

        puts "Processing the #{repo_prs.size} PR's from #{repo}"
        repo_prs.each do |pr|
          # skip any straight up closed PRs
          next if pr.merged_at.nil? && !!pr.closed_at
          # skip the wip ones, no reviews required
          next if pr.title.match(STARTS_WITH_WIP)
          # skip the bot ones
          next if pr.user.login.match(USER_IS_BOT)

          analyzer = Analyzer.new(client: client, repo: repo, pr: pr)

          pr_retry_count = 1
          while(pr_retry_count <= 3)
            pr_retry_count += 1
            begin
              if analyzed_pr = analyzer.process
                extracted_pull_requests << analyzed_pr
                break
              end
            rescue Octokit::BadGateway => e
              puts e.message
              if pr_retry_count == 3
                puts "failed to process pr: #{pr.html_url}"
              end
            end
          end
        end
      end

      extracted_pull_requests
    end
  end
end
