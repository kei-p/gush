module Gush
  class CLI
    class Overview
      attr_reader :workflow

      def initialize(workflow)
        @workflow = workflow
      end

      def table
        Terminal::Table.new(rows: rows)
      end

      def status
        if workflow.failed?
          failed_status
        elsif workflow.running?
          running_status
        elsif workflow.finished?
          "done".green
        elsif workflow.stopped?
          "stopped".red
        else
          "pending".light_white
        end
      end

      def jobs_list(jobs)
        "\nJobs list:\n".tap do |output|
          jobs_by_type(jobs).each do |job|
            output << job_to_list_element(job)
          end
        end
      end

      private
      def rows
        [].tap do |rows|
          columns.each_pair do |name, value|
            rows << [{alignment: :center, value: name}, value]
            rows << :separator if name != "Status"
          end
        end
      end

      def columns
        {
          "ID" => workflow.id,
          "Name" => workflow.class.to_s,
          "Jobs" => workflow.jobs.count,
          "Failed jobs" => failed_jobs_count.red,
          "Succeeded jobs" => succeeded_jobs_count.green,
          "Enqueued jobs" => enqueued_jobs_count.yellow,
          "Running jobs" => running_jobs_count.blue,
          "Remaining jobs" => remaining_jobs_count,
          "Status" => status
        }
      end

      def running_status
        finished = succeeded_jobs_count.to_i
        status = "running".yellow
        status += "\n#{finished}/#{total_jobs_count} [#{(finished*100)/total_jobs_count}%]"
      end

      def failed_status
        status = "failed".light_red
        status += "\n#{failed_job} failed"
      end

      def job_to_list_element(job)
        name = job.name
        case
        when job.failed?
          "[✗] #{name.red} \n"
        when job.finished?
          "[✓] #{name.green} \n"
        when job.enqueued?
          "[•] #{name.yellow} \n"
        when job.running?
          "[•] #{name.blue} \n"
        else
          "[ ] #{name} \n"
        end
      end

      def jobs_by_type(type)
        return sorted_jobs if type == :all
        jobs.select{|j| j.public_send("#{type}?") }
      end

      def sorted_jobs
        workflow.jobs.sort_by do |job|
          case
          when job.failed?
            0
          when job.finished?
            1
          when job.enqueued?
            2
          when job.running?
            3
          else
            4
          end
        end
      end

      def failed_job
        workflow.jobs.find(&:failed).name
      end

      def total_jobs_count
        workflow.jobs.count
      end

      def failed_jobs_count
        workflow.jobs.count(&:failed?).to_s
      end

      def succeeded_jobs_count
        workflow.jobs.count(&:succeeded?).to_s
      end

      def enqueued_jobs_count
        workflow.jobs.count(&:enqueued?).to_s
      end

      def running_jobs_count
        workflow.jobs.count(&:running?).to_s
      end

      def remaining_jobs_count
        workflow.jobs.count{|j| [j.finished, j.failed, j.enqueued].none? }.to_s
      end
    end
  end
end
