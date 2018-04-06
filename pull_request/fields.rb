module PullRequest
  class Fields
    COLS = %i(
      repo
      href
      number
      user_id
      user_login
      created_at
      closed_at
      merged_at
      days_to_first_review
      time_to_first_review
      time_to_approval
      approval_to_merge
      time_to_merge
    )

    def self.hash_with_defaults
      pr_details = {}
      COLS.each do |field|
        pr_details[field] = nil
      end
      pr_details
    end
  end
end
