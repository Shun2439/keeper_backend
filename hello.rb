require 'sinatra'

set :environemnt, :production

get '/' do
  "Hello, A Whole New World!"
end

