require 'net/http'
require 'json'

def get_value_from_env(key, required: true, default: '')
    value = ENV[key]
    abort("The value with key '#{key}' can't be found in the ENV variables, please set the key and its value in the 'User-Defined' section in 'Build Settings' of your host application.") if required && value == nil
    value = default if value == nil
    value
end

# Continue only if the value with key 'BD_JSB_GECKO_ACCESS_KEY' exists.
access_key = get_value_from_env('BD_JSB_GECKO_ACCESS_KEY', required: false)
exit(0) if access_key.empty?

$resource_path = File.join(ENV['TARGET_BUILD_DIR'], ENV['UNLOCALIZED_RESOURCES_FOLDER_PATH'])
output_file = File.join($resource_path, 'jsb_auth_infos.json')
compressed_file = output_file + '.gz'
retry_interval = 5
retry_count = 3
app_version = get_value_from_env('VERSION_NUMBER')
app_id = get_value_from_env('BD_APP_ID')
extra_channels = get_value_from_env('BD_JSB_GECKO_EXTRA_CHANNELS', required: false)
host = get_value_from_env('BD_JSB_GECKO_DOMAIN')
uri = URI("https://#{host}/src/server/v2/package")
channels = extra_channels.split(',').map(&:strip).unshift('_jsb_auth')
is_dev_mode = get_value_from_env('BD_DEV_MODE', required: false) == 'YES'

# Prepare request parameters
params = {
    'common' => {
        'aid' => app_id.to_i,
        'app_version' => app_version,
        'os' => 1,
    },
    'deployment' => {
        access_key => channels.map do |channel|
            {
                'channel': channel,
                'local_version': 0,
            }
        end
    },
}

begin
    if is_dev_mode && File.file?(compressed_file)
        puts("Cancel fetching JSB auth infos in dev mode since the file '#{compressed_file}' exists already.")
        exit(0)
    end

    # Send POST request and retry if needed
    puts("Start fetching JSB auth infos.")
    retries ||= 0
    http = Net::HTTP.new(uri.host, uri.port);
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = params.to_json
    response = http.request(request)
    json = JSON.parse(response.read_body)
    raise("status code isn't equal to zero. response body <#{response.read_body}>") unless json['status'] == 0
    raise("auth infos for access key '#{access_key}' is empty. response body <#{response.read_body}>") unless json['data']['packages'][access_key].count > 0

    # Save auth infos into the destination file
    File.open(output_file, 'w') do |file|
        file.write(response.read_body)
    end

    # Compress the output file
    raise("failed to compress file #{output_file} into #{compressed_file}") unless system("/usr/bin/gzip -f #{output_file}")

    puts("Finish fetching JSB auth infos and save it into file '#{compressed_file}'.")
rescue => e
    retries += 1
    should_retry = retries < retry_count
    puts("Retrying in #{retry_interval}s due to error: #{e}.") if should_retry
    $stdout.flush   # Print string immediately
    abort("Failed to fetch or save JSB auth infos due to error: #{e}.") unless should_retry
    sleep(retry_interval) if should_retry
    retry if should_retry
end

