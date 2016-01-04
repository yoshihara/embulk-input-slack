require "embulk/input/slack_api/client"

module Embulk
  module Input

    class Slack < InputPlugin
      CHANNEL_API = "https://slack.com/api/channels.list".freeze
      USERS_API = "https://slack.com/api/users.list".freeze
      HISTORY_API = "https://slack.com/api/channels.history".freeze

      Plugin.register_input("slack", self)

      def self.transaction(config, &control)
        # configuration code:
        task = {
          "option1" => config.param("option1", :integer),                     # integer, required
          "option2" => config.param("option2", :string, default: "myvalue"),  # string, optional
          "option3" => config.param("option3", :string, default: nil),        # string, optional
        }

        columns = [
          Column.new(0, "example", :string),
          Column.new(1, "column", :long),
          Column.new(2, "value", :double),
        ]

        resume(task, columns, 1, &control)
      end

      def self.resume(task, columns, count, &control)
        task_reports = yield(task, columns, count)

        next_config_diff = {}
        return next_config_diff
      end

      def self.guess(config)
        token = config.param("token", :string)
        from = config.param("from", :string, default: nil)
        to = config.param("to", :string, default: nil)

        from = from ? Time.parse(from).to_i : 0
        to = to ? Time.parse(to).to_i : Time.now.to_i

        client = SlackApi::Client.new(token)

        channels = client.channels
        records = []

        channels.each do |channel|
          records += client.history(channel[:id], channel[:name], from, to)
        end

        columns = Guess::SchemaGuess.from_hash_records(records)
        return {"columns" => columns}
      end

      def init
        # initialization code:
        @option1 = task["option1"]
        @option2 = task["option2"]
        @option3 = task["option3"]
      end

      def run
        page_builder.add(["example-value", 1, 0.1])
        page_builder.add(["example-value", 2, 0.2])
        page_builder.finish

        task_report = {}
        return task_report
      end
    end

  end
end
