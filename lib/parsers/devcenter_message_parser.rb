require 'json'
require 'time'

# Take a string and return a value-hash known to the event manager api
#
# Sample ArticleRead DC event message:
#
# {
#   "user_heroku_uid":"351369@users.heroku.com","user_email":"pdmjoe@gmail.com","article_id":650,"article_slug":"quickstart",
#   "article_status":"published","article_title":"Getting Started with Heroku","article_owner_id":58,"article_owner_email":"jon@heroku.com",
#   "at":"2013-01-04T18:59:18+00:00","event_type":"ArticleRead"
# }
#
# Sample parsed value hash:
#
# {
#   :actor_id=>351369, :actor=>"pdmjoe@gmail.com", :target_id=>650, :target=>"quickstart", :owner_id=>58, :owner=>"jon@heroku.com",
#   :timestamp=>1357325958, :action=>"view-article", :attributes=>{:article_status=>"published", :article_title=>"Getting Started with Heroku"}
# }

class DevcenterMessageParser

  EVENT_MSG_REGEX = /"event_type":"ArticleRead"/

  DEVCENTER_EVENT_MANAGER_KEY_MAPPINGS = {
    'at' => lambda { |v| { timestamp: Time.parse(v).to_i }},
    'event_type' => lambda { |v| { action: 'view-article' } if v == 'ArticleRead' },
    'user_heroku_uid' => lambda { |v| { actor_id: v.to_i }},
    'user_email' => lambda { |v| { actor: v }},
    'article_slug' => lambda { |v| { target: v }},
    'article_id' => lambda { |v| { target_id: v }},
    'article_owner_id' => lambda { |v| { owner_id: v }},
    'article_owner_email' => lambda { |v| { owner: v }}
  }

  class << self

    def parse(log_msg)
      if(EVENT_MSG_REGEX.match(log_msg))
        message_values = JSON.parse(log_msg).to_hash
        parsed_values = extract_basic_values(message_values)
        parsed_values.merge!(attributes: extract_attributes_values(message_values))
        parsed_values.merge!(static_values)
        parsed_values
      end
    end

    def extract_basic_values(values)
      values.inject({}) do |result, (key, value)|
        mapper = DEVCENTER_EVENT_MANAGER_KEY_MAPPINGS[key]
        result.merge!(mapper.call(value)) if mapper
        result
      end
    end

    def extract_attributes_values(values)
      { article_status: values['article_status'], article_title: values['article_title'] }
    end

    def static_values
      {
        'cloud' => ENV['EVENT_MANAGER_CLOUD'],
        'component' => ENV['EVENT_MANAGER_COMPONENT'],
        'type' => ENV['EVENT_MANAGER_EVENT_ENTITY_TYPE'],
        'source_ip' => '0.0.0.0'
      }
    end
  end
end