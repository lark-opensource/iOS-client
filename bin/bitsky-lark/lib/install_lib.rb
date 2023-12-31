require 'yaml'
require 'set'
require 'json'
require 'open-uri'
require 'fileutils'
require 'thread'
require 'progressbar'
require 'cocoapods'
require 'cocoapods-bitsky'
require 'Singleton'

def parse_pod_version(lock_file)
  lock_content = YAML.load_file(lock_file)
  third_party_version_hash = {}
  first_party_spec_hash = {}

  lock_content['EXTERNAL SOURCES'].each do |key, value|
    pod_spec_dir = File.dirname(lock_file) + '/' + value[:path]
    first_party_spec_hash[key] = pod_spec_dir + "/#{key}.podspec"
  end
  first_party_pods = first_party_spec_hash.keys

  lock_content['PODS'].each do |pod|
    if pod.is_a? String
      name_version = pod
    elsif pod.is_a? Hash
      name_version = pod.keys[0]
    else
      raise "Podfile.lock parse error! #{pod}"
    end
    components = name_version.split(' ')
    name = components[0].split('/')[0]
    version = components[1][1...-1]
    third_party_version_hash[name] = version unless first_party_pods.include? name
  end

  [first_party_spec_hash, third_party_version_hash]
end

def download(pod_name, pod_version, cache_dir, download_dir, download_temp_dir)
  download_url = "https://tosv.byted.org/obj/piserver-oss/bazel/#{pod_name}/#{pod_version}/#{pod_name}.tar.xz"

  # 1.判断download_dir是否已经存在组件，以及对应的版本
  spec_file = "#{download_dir}/#{pod_name}/#{pod_name}.podspec.json"
  spec_content = File.exist?(spec_file) ? JSON.load(File.read(spec_file)) : {}
  spec_version = spec_content['version'] || 'not_existed'
  if spec_version == pod_version
    puts "#{pod_name} skip download with version: #{pod_version}'s download, already in #{download_dir}"
    need_download = false
  else
    need_download = true
  end

  # 2.判断cache_dir是否已经存在组件，以及对应的版本
  if need_download
    spec_file = "#{cache_dir}/#{pod_name}/#{pod_name}.podspec.json"
    spec_content = File.exist?(spec_file) ? JSON.load(File.read(spec_file)) : {}
    spec_version = spec_content['version'] || 'not_existed'
    if spec_version == pod_version
      puts "#{pod_name} skip download with version: #{pod_version}'s download, already in #{cache_dir}"
      # 将cache_dir/pod_name中内容，软链到download_dir
      FileUtils.rm_rf("#{download_dir}/#{pod_name}")
      FileUtils.mkdir_p("#{download_dir}/#{pod_name}")
      Dir.entries("#{cache_dir}/#{pod_name}").each do |entry|
        next if %w[. .. BUILD BUILD.bazel xcconfig.bzl WORKSPACE].include?(entry)
        FileUtils.ln_s("#{cache_dir}/#{pod_name}/#{entry}", "#{download_dir}/#{pod_name}/#{entry}", :force => true)
      end
      need_download = false
    else
      need_download = true
    end
  end

  # 3.如果需要下载，则开始下载
  if need_download
    FileUtils.rm_rf("#{download_dir}/#{pod_name}")
    puts "#{pod_name} downloading with version #{pod_version} to #{download_temp_dir}/#{pod_name}.tar.xz"

    max_retries = 3
    retries = 0
    begin
      FileUtils.mkdir_p(download_temp_dir)
      download_result = system("curl -o #{download_temp_dir}/#{pod_name}.tar.xz #{download_url} > /dev/null 2>&1")
      raise unless download_result
    rescue => exception
      retries += 1
      if retries <= max_retries
        puts "#{pod_name} download failed with error: #{exception.message}. Retrying (attempt #{retries})..."
        retry
      else
        puts "#{pod_name} download failed after #{max_retries} attempts. Giving up."
      end
    end
    FileUtils.mkdir_p "#{download_dir}/#{pod_name}"
    decompress_result = system("LC_ALL=C tar -xf #{download_temp_dir}/#{pod_name}.tar.xz -C #{download_dir} > /dev/null 2>&1")
    raise "#{pod_name} decompressing failed" unless decompress_result
  end
end

def download_pods(pod_version_hash, cache_dir, download_dir)
  temp_dir = 'temp_dir'

  # 1.创建下载目录
  FileUtils.mkdir_p(download_dir) unless File.directory? download_dir

  # 2.准备下载，删除不需要的组件目录，创建下载临时目录
  Dir.children(download_dir).each do |child_dir|
    full_path = "#{download_dir}/#{child_dir}"
    FileUtils.rm_rf full_path if File.directory?(full_path) && !pod_version_hash.include?(child_dir)
  end

  # 3.开始下载
  progressbar = ProgressBar.create(:total => pod_version_hash.size, :format => '%a %e %P% Processed: %c from %C')
  threads = []
  pod_version_hash.each do |pod_name, version|
    threads << Thread.new do
      download(pod_name, version, cache_dir, download_dir, "#{download_dir}/#{temp_dir}")
      progressbar.increment
    end
  end
  threads.each(&:join)

  # 4.删除临时目录
  FileUtils.rm_rf("#{download_dir}/#{temp_dir}")

  third_party_spec_hash = {}
  pod_version_hash.each do |key, _|
    third_party_spec_hash[key] = download_dir + '/' + key + "/" + "#{key}.podspec.json"
  end
  third_party_spec_hash
end

def soft_link_first_party_pods(first_party_spec_hash, download_dir)
  # 1.创建下载目录
  FileUtils.mkdir_p(download_dir) unless File.directory? download_dir

  new_hash = {}
  # 2.将所有一方组件软链到bitsky_external下
  first_party_spec_hash.each do |pod_name, spec_path|
    FileUtils.rm_rf("#{download_dir}/#{pod_name}")
    FileUtils.mkdir_p("#{download_dir}/#{pod_name}")
    spec_dir = File.dirname(spec_path)
    Dir.entries(spec_dir).each do |entry|
      next if %w[. .. BUILD BUILD.bazel xcconfig.bzl WORKSPACE].include?(entry)
      FileUtils.ln_s("#{spec_dir}/#{entry}", "#{download_dir}/#{pod_name}/#{entry}", :force => true)
    end
    new_hash[pod_name] = "#{download_dir}/#{pod_name}/#{File.basename(spec_path)}"
  end
  new_hash
end

def generate_lldb_source_map(first_party_pods, external_dir)
  # TODO: if ci return
  source_map = {}
  first_party_pods.each do |pod_name, spec_path|
    key = external_dir + '/' + pod_name
    value = File.dirname(File.realpath(spec_path))
    source_map[key] = value
  end
  # save source_map to json file
  File.open('.bitsky/lldb_source_map.json', 'w') do |f|
    f.write(source_map.to_json)
  end
end

def convert_podspec_to_build(first_party_spec_hash, third_party_spec_hash, framework_pods, bitsky_external, lock_file)
  # Generate first party pod BUILD
  monorepo = ::CocoapodsBitsky::Monorepo.new  
  monorepo.parse_module(lock_file, true, first_party_spec_hash.values)
  monorepo.install("Modules", lock_file, nil, true, nil, true, true, nil, third_party_spec_hash, true)

  # Generate third party pod BUILD
  gen_buid_cmd = "bitsky prebuild --generate_build --lock_file #{lock_file} --bazel_external #{bitsky_external}"
  third_party_spec_hash.each do |pod_name, _|
    gen_buid_cmd = gen_buid_cmd + " --specify_pods #{pod_name}"
  end

  framework_pods.each do |pod_name|
    gen_buid_cmd = gen_buid_cmd + " --use_framework #{pod_name}"
  end
  raise "xxx" unless system("bitsky prebuild")
  puts gen_buid_cmd
  gen_result = system(gen_buid_cmd)  
  raise unless gen_result
end

def generate_module_json(podfile_lock, outout)
  spec_targets = YAML.load_file(podfile_lock)['SPECS TARGET']
  module_json = {}
  spec_targets.each do |key, value|
    if key != "Pod" and value.length > 0
      module_json[key] = value.map { |v| (v.split('/')[0]).gsub("+", "_plus_") } .map { |v| "@#{v}//:#{key}_#{v}" }.uniq
    end    
  end
  File.write(outout, JSON.pretty_generate(module_json))
end