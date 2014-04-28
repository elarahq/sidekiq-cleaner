module Sidekiq::Cleaner
  class JobAggregator
    def initialize(jobs)
      @jobs = jobs
    end

    def self.group_by(jobs, group_by_attribute, attribute_value)
      memo = {}

      memo["AllErrors"] = {}
      memo["AllErrors"]['total_failures'] = 0

      jobs.each do |job|
        attr = job[group_by_attribute]
        attr_val = job[attribute_value]
        if memo[attr] && memo[attr][attr_val]
          memo[attr][attr_val] += 1
          memo[attr]['total_failures'] += 1

          memo["AllErrors"][attr_val] += 1
          memo["AllErrors"]['total_failures'] += 1

        else
          unless memo[attr]
            memo[attr] = {}
            memo[attr]['total_failures'] = 0

            memo["AllErrors"][attr_val] = 0
          end

          memo[attr][attr_val] = 1
          memo[attr]['total_failures'] += 1

          memo["AllErrors"][attr_val] = 1
          memo["AllErrors"]['total_failures'] += 1

        end
      end

      memo
    end


  end
end