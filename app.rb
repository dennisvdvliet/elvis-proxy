require 'rubygems'
require 'sinatra'
require 'json'
require 'open-uri'
require "faraday_middleware"
require "faraday/conductivity"

require "sinatra/reloader" if development?

class ApiAuthentication < Faraday::Middleware
  def call(env)
    env[:request_headers]["Cookie"] = "JSESSIONID=#{elvis_session}"
    @app.call(env)
  end
end

before do
   content_type :json
   headers 'Access-Control-Allow-Origin' => request.env["HTTP_ORIGIN"], 'Access-Control-Allow-Credentials' => 'true', 'Access-Control-Allow-Headers' => '', 'Access-Control-Allow-Methods' => 'POST,GET,OPTIONS', "Set-Cookie" => "JSESSIONID=#{elvis_session}"
end


get '/*' do
  d =   elvis_get(current_uri).body
  d
end

post '/login' do
  {
  "loginSuccess" => true,
  "serverVersion" => "4.4.3.894",
  "sessionId" => elvis_session
  }.to_json
end

post '/*' do
  logger.info request.env
  elvis_post(current_uri).body
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
  [elvis_url, "/services/login?username=nlvlied&password=P2iScKMv&clientType=api_1234"].join
end

def elvis_session
  @@elvis_session ||= get_elvis_session
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
    @@elvis_session = nil
    get_elvis_session
    data = @connection.get(uri)
  end
  return data
end


def elvis_post(uri)
  connection
  begin
    logger.info "Awesome"
    data = @connection.post do |req|
      req.url uri
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'

      #req.body = "q=han"
      req.body = URI.encode_www_form params.select!{|k,v| k != "splat" && k != "captures"}
    end
  rescue
    logger.info "Catch error"
    @@elvis_session = nil
    get_elvis_session
    data = @connection.post do |req|
      req.url uri
      #req.body = "q=han"
      req.body = URI.encode_www_form params.select!{|k,v| k != "splat" && k != "captures"}
    end
  end
  return data
end
