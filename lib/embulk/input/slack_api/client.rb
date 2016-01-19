require "httpclient"
require "json"

module Embulk
  module Input
    module SlackApi
      class Client
        CHANNEL_API = "https://slack.com/api/channels.list".freeze
        USERS_API = "https://slack.com/api/users.list".freeze
        HISTORY_API = "https://slack.com/api/channels.history".freeze

        def initialize(token)
          @default_params = {token: token}
          @client = HTTPClient.new
        end

        def history(channel_name, from, to, count: 1000, fetch_all: false)
          channel_id = channel_id(channel_name)

          params = @default_params.merge(channel: channel_id, count: count, oldest: from, latest: to)
          Enumerator.new do |histories|
            loop do
              response = JSON.parse(@client.get(HISTORY_API, params).body)

              raise ConfigError.new(response["error"]) unless response["ok"]

              response["messages"].each do |message|
                histories << {channel: channel_name}.merge(convert(message))
              end

              if fetch_all && response["has_more"]
                last_ts = histories.last["ts"]
                params = params.merge(latest: last_ts)
              else
                break
              end
            end
          end
        end

        def channels
          return @channels if @channels

          params = @default_params.merge(exclude_archived: true)
          response = JSON.parse(@client.get(CHANNEL_API, params).body)

          channels = response["channels"].collect {|channel| {id: channel["id"], name: channel["name"]}}

          @channels = channels
        end

        def channel_id(channel_name)
          channel_name = channel_name.gsub(/^#/, "")
          target_channel = channels.detect {|channel| channel[:name] == channel_name }
          unless target_channel
            raise ConfigError.new("no exist channel: ##{channel_name}")
          end

          target_channel[:id]
        end

        private

        def users
          return @users if @users

          response = JSON.parse(@client.get(USERS_API, @default_params).body)
          users = {}

          response["members"].each {|member| users[member["id"]] = member["name"]}
          @users = users
        end

        def convert(message)
          record = {}
          message.each_pair do |key, value|
            record[key] =
              case key
              when "attachement"
                value.to_s
              when "ts"
                Time.at(value.to_i)
              when "user"
                users[message["user"]]
              else
                value.to_json
              end
          end

          record
        end
      end
    end
  end
end

