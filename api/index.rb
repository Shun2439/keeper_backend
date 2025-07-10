require_relative '../app/webcal'  

Handler = Proc.new do |request, response|
  app = MyApp.new
  # puts "Requestttttt: #{request.request_method} #{request.path} #{request.query_string} #{request.body}"
  env = {
    'REQUEST_METHOD' => request.request_method,
    'PATH_INFO' => request.path,
    'QUERY_STRING' => request.query_string,
    'rack.input' => StringIO.new(request.body || "")
  }

  status, headers, body = app.call(env)

  response.status = status
  headers.each { |key, value| response[key] = value }

  response.body = body.join
end