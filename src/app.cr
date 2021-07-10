require "option_parser"

require "./constants"

# Server defaults
host = PlaceOS::FrontendLoader::HOST
port = PlaceOS::FrontendLoader::PORT

# Application configuration
content_directory = nil
update_crontab = nil
git_username = nil
git_password = nil

# Command line options
OptionParser.parse(ARGV.dup) do |parser|
  parser.banner = "Usage: #{PlaceOS::FrontendLoader::APP_NAME} [arguments]"

  # Application flags
  parser.on("--www=CONTENT_DIR", "Specifies the content directory") { |d| content_directory = d }
  parser.on("--update-crontab=CRON", "Specifies the update crontab") { |c| update_crontab = c }
  parser.on("--git-username=USERNAME", "Specifies the git username") { |u| git_username = u }
  parser.on("--git-password=PASSWORD", "Specifies the git password") { |p| git_password = p }

  # Server flags
  parser.on("-b HOST", "--bind=HOST", "Specifies the server host") { |h| host = h }
  parser.on("-p PORT", "--port=PORT", "Specifies the server port") { |p| port = p.to_i }
  parser.on("-r", "--routes", "List the application routes") do
    ActionController::Server.print_routes
    exit 0
  end

  parser.on("-v", "--version", "Display the application version") do
    puts "#{PlaceOS::FrontendLoader::APP_NAME} v#{PlaceOS::FrontendLoader::VERSION}"
    exit 0
  end

  parser.on("-c URL", "--curl=URL", "Perform a basic health check by requesting the URL") do |url|
    begin
      response = HTTP::Client.get url
      exit 0 if (200..499).includes? response.status_code
      puts "health check failed, received response code #{response.status_code}"
      exit 1
    rescue error
      puts error.inspect_with_backtrace(STDOUT)
      exit 2
    end
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} unrecognised"
    puts parser
    exit 1
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit 0
  end
end

require "./config"

# Configure the loader

PlaceOS::FrontendLoader::Loader.configure do |settings|
  content_directory.try { |cd| settings.content_directory = cd }
  update_crontab.try { |uc| settings.update_crontab = uc }
  git_username.try { |gu| settings.username = gu }
  git_password.try { |gp| settings.password = gp }
end

# Start the loader

PlaceOS::FrontendLoader::Loader.instance.start

# Server Configuration

server = ActionController::Server.new(port, host)

terminate = Proc(Signal, Nil).new do |signal|
  puts " > terminating gracefully"
  spawn { server.close }
  signal.ignore
end

# Detect ctr-c to shutdown gracefully
# Docker containers use the term signal
Signal::INT.trap &terminate
Signal::TERM.trap &terminate

# Allow signals to change the log level at run-time
logging = Proc(Signal, Nil).new do |signal|
  level = signal.usr1? ? Log::Severity::Debug : Log::Severity::Info
  puts " > Log level changed to #{level}"
  Log.builder.bind "*", level, PlaceOS::LogBackend.log_backend
  signal.ignore
end

# Turn on DEBUG level logging `kill -s USR1 %PID`
# Default production log levels (INFO and above) `kill -s USR2 %PID`
Signal::USR1.trap &logging
Signal::USR2.trap &logging

# Start the server
server.run do
  puts "Listening on #{server.print_addresses}"
end

# Shutdown message
puts "#{PlaceOS::FrontendLoader::APP_NAME} leaps through the veldt\n"
