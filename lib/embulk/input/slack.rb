require "embulk/input/slack_api/client"

module Embulk
  module Input

    class Slack < InputPlugin
      Plugin.register_input("slack", self)

      def self.transaction(config, &control)
        # configuration code:
        token = config.param("token", :string)
        channel_name = config.param("channel", :string, default: nil)
        client = SlackApi::Client.new(token)

        columns = config.param(:columns, :array)

        from = config.param("from", :string, default: nil)
        to = config.param("to", :string, default: nil)

        task = {
          token: token,
          channel_name: channel_name,
          from: from,
          to: to,
          schema: columns,
        }

        columns = task[:schema].map do |column|
          name = column["name"]
          type = column["type"].to_sym

          Column.new(nil, name, type, column["format"])
        end

        resume(task, columns, 1, &control)
      end

      def self.resume(task, columns, count, &control)
        task_reports = yield(task, columns, count)

        next_config_diff = {}
        return next_config_diff
      end

      def self.guess(config)
        token = config.param("token", :string)
        channel_name = config.param("channel", :string, default: nil)
        from = config.param("from", :string, default: nil)
        to = config.param("to", :string, default: nil)

        from, to = adjust_range(from, to)

        client = SlackApi::Client.new(token)

        records = []

        if channel_name
          records = client.history(channel_name, from, to)
        else
          channels.each do |channel|
            records += client.history(channel[:name], from, to)
          end
        end

        columns = Guess::SchemaGuess.from_hash_records(records)
        return {"columns" => columns}
      end

      def self.adjust_range(from, to)
        adjusted_from = from ? Time.parse(from).to_i : 0
        adjusted_to = to ? Time.parse(to).to_i : Time.now.to_i

        [adjusted_from, adjusted_to]
      end

      def init
        @client = SlackApi::Client.new(task[:token])
        @channel_name = task[:channel_name]

        from = task[:from]
        @from = from ? Time.parse(from).to_i : 0

        to = task[:to]
        @to = to ? Time.parse(to).to_i : Time.now.to_i
        @schema = task[:schema]
      end

      def run
        if @channel_name
          @client.history(@channel_name, @from, @to, fetch_all: true).each do |channel|
            page_builder.add(extract_values(@channel_name, channel))
          end

        else
          @client.channels.each do |channel|
            @client.history(channel[:name], @from, @to, fetch_all: true).each do |channel|
              # schemaの順番に並べる
              page_builder.add(extract_values(channel[:name], channel))
            end
          end
        end

        page_builder.finish

        task_report = {}
        return task_report
      end

      private

      def extract_values(channel_name, record)
        @schema.map do |column|
          if column["name"] == "channel"
            channel_name
          else
            record[column["name"]]
          end
        end
      end

      def adjusted_range(*args)
        self.class.adjust_range(*args)
      end
    end

  end
end
