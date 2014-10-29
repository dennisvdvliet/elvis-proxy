require 'sinatra'

set     :env, :development
disable :run

require './app.rb'

run Sinatra::Application