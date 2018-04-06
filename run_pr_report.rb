require 'pry'
require 'business_time'
require 'csv'
require_relative 'pull_request/fields'
require_relative 'pull_request/processor'

csv_out_path = "data/pull_requests_data.csv"

if true || !File.exist?(csv_out_path)
  pr_processor = PullRequest::Processor.new(
    token: ENV['GITHUB_OAUTH_TOKEN']
  )
  analyzed_prs = pr_processor.analyze_all_repo_pull_requests

  puts "Outputting the #{analyzed_prs.size} formatted PR's to #{csv_out_path}"

  output_headers = PullRequest::Fields::COLS

  CSV.open(csv_out_path, "wb") do |csv|
    csv << output_headers

    analyzed_prs.each do |pr|
      csv << pr.values_at(*output_headers)
    end
  end
end
