require 'rubygems'
require 'sinatra'
require 'json'
require 'open-uri'
require "faraday_middleware"
require "faraday/conductivity"

require "sinatra/reloader"

class ApiAuthentication < Faraday::Middleware
  def call(env)
    env[:request_headers]["Cookie"] = "JSESSIONID=#{elvis_session}"
    @app.call(env)
  end
end



get '/*' do
  current_uri
  request.env
  content_type :json
  logger.debug elvis_session
  elvis_get(current_uri).body
end


def current_uri
  request.env["REQUEST_URI"]
end

def proxy
  {
    :session => elvis_session,
    :url => elvis_full_path,
    :auth_path => elvis_auth_path
  }

end

def elvis_login_url
  [elvis_url, "/services/login?username=nlvlied&password=P2iScKMv"].join
end

def elvis_session
  @elvis_session ||= get_elvis_session
end

def get_elvis_session
  #logger.debug "Resetting Elvis session"
  data = JSON.parse(open(elvis_login_url).read)
  data["sessionId"]
end

def elvis_url
  "https://elvis.g-star.com"
end

def elvis_full_path
  [elvis_url, current_uri].join
end

def elvis_auth_path
  [elvis_full_path, ";sessionId=", elvis_session].join
end


def connection
  @connection ||= Faraday.new(url: elvis_url) do |faraday|
    faraday.use Faraday::Response::RaiseError
    faraday.response :logger
    faraday.use ApiAuthentication
    faraday.adapter  Faraday.default_adapter
  end
end

def elvis_get(uri)
  connection
  begin
    logger.info "Awesome"
    data = @connection.get(uri)
  rescue
    logger.info "Catch error"
    @elvis_session = nil
    get_elvis_session
    data = @connection.get(uri)
  end
  return data
end

