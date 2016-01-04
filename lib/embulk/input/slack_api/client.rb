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

        def history(channel_id, channel_name, from, to, count: 1000, fetch_all: false)
          # TODO: fetch_allがtrueでhas_moreがtrueだったときの処理を追加する（ブロック渡しにする）
          params = @default_params.merge(channel: channel_id, count: count, oldest: from, latest: to)
          response = JSON.parse(@client.get(HISTORY_API, params).body)

          raise ConfigError.new(response["error"]) unless response["ok"]

          response["messages"].map do |message|
            {channel: channel_name}.merge(convert(message))
          end
        end

        def channels
          return @channels if @channels

          params = @default_params.merge(exclude_archived: true)
          response = JSON.parse(@client.get(CHANNEL_API, params).body)

          channels = response["channels"].collect {|channel| {id: channel["id"], name: channel["name"]}}

          @channels = channels
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
                value
              end
          end

          record
        end
      end
    end
  end
end

