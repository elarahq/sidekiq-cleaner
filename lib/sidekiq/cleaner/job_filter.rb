module Sidekiq
  module Cleaner
    class JobFilter
      class << self
        def filter_dead_jobs_by_params(params)
          req_failure_class = params['failure_class']
          req_bucket_name = params['bucket_name']
          req_error_class = params['error_class']

          dead = filter_dead_jobs({'failure_class' => req_failure_class,
                                   'bucket_name' => req_bucket_name,
                                   'error_class' => req_error_class})

          return dead, req_failure_class, req_bucket_name, req_error_class
        end


        def filter_dead_jobs(filters={})
          # filters can have keys in (job_failure_class, job_error_class, job_bucket_name)
          dead_jobs = []
          Sidekiq::Cleaner::DeadJob.for_each do |job_features|
            filter_passed = 1
            filters.each do |filter, value|
              next if value.nil?

              # If bucket name is total_failures always include the job
              next if filter == "bucket_name" && value == "total_failures"

              # If failure_class is "AllErrors", always include the job
              next if filter == "failure_class" && value == "AllErrors"

              # If error_class is "AllErrors", always include the job
              next if filter == "error_class" && value == "AllErrors"

              filter_passed = 0 if job_features[filter] != value
            end
            dead_jobs << job_features if filter_passed == 1
          end

          dead_jobs
        end
      end
    end
  end
end
