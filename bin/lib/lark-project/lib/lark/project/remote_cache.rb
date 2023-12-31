#环境变量
#REMOTE_CACHE_ENABLE: 是否开启开启远程缓存，如果远端没有缓存，会fallback到二进制，会覆盖remote_cache_enable参数
#REMOTE_CACHE_MODE: 可选值consumer、producer、producer-fast
#REMOTE_CACHE_CONFIGURATION: 可选值Rlease、Debug，会覆盖remote_cache_platform参数
#REMOTE_CACHE_PLATFORM: 可选值iphoneos、iphonesimulator，会覆盖remote_cache_platform参数

require 'lark/project/environment'
# 推荐使用这个缩写来获取环境相关配置
$lark_env ||= Lark::Project::Environment.instance

#参数
#remote_cache_enable: 是否开启远程缓存
#primary_branch: 尝试去复用缓存的分支
#final_target: 最终编译的target
#exclude_targets: 忽略的targets
#hummer_tags: 会按照缓存使用情况，注入hummer_tags

def try_to_enable_remote_cache(options)
	remote_cache_enable = ((ENV["REMOTE_CACHE_ENABLE"] || options[:remote_cache_enable].to_s) == "true")	
    remote_cache_mode = ENV["REMOTE_CACHE_MODE"] || "consumer"	
	remote_cache_configuration = ENV["REMOTE_CACHE_CONFIGURATION"] || options[:remote_cache_configuration] || "Debug"
	remote_cache_platform = ENV["REMOTE_CACHE_PLATFORM"] || options[:remote_cache_platform] || ($lark_env.ci? ? "iphonesimulator" : "iphonesimulator iphoneos")

	last_time_remote_cache_enabled = File.exists? ".rc/.remote_cache_mark"
	File.delete ".rc/.remote_cache_mark" if File.exists? ".rc/.remote_cache_mark"

	should_use_sim_arm = true
	actual_remote_cache_platform = Array.new
	if remote_cache_platform.include? "iphoneos"
		actual_remote_cache_platform << "iphoneos_arm64"
	end
	if remote_cache_platform.include? "iphonesimulator"
		sim_arch = should_use_sim_arm ? "arm64" : "x86_64"
		actual_remote_cache_platform << ("iphonesimulator_" + sim_arch)
	end
	remote_cache_platform = actual_remote_cache_platform.join(" ")

	primary_branch = options[:primary_branch]
	final_target = options[:final_target] || ""
	exclude_targets = options[:exclude_targets] || []	
	custom_fingerprint_envs = options[:custom_fingerprint_envs] || []	
    irrelevant_dependencies_paths = options[:irrelevant_dependencies_paths] || ['\\.modulemap$', "\\-Swift\\.h$", "\\/RustPB\\.swiftmodule", "\\/ServerPB\\.swiftmodule", "\\-umbrella\\.h$", "externalDependency\\/RustPB$", "externalDependency\\/LarkSQLCipher$", "externalDependency\\/RustSDK$", "externalDependency\\/RustSimpleLogSDK$"]
	hummer_tags = options[:hummer_tags] || {}
    scheme_tag = options[:scheme_tag] || {}
	ignore_external_subspec_change = options[:ignore_external_subspec_change] || false

	lldb_contents = clean_lldbinit('LLDBInitFile')	
	File.write('LLDBInitFile', lldb_contents.join("\n"), mode: "w")

	if (ENV["NEED_RUN_UNIT_TEST"] || "")  == "true"
		scheme_tag += "-unittest"
	end

	schema_version = "112-#{scheme_tag}.1"

	`sed -i '' 's/schema_version.*/schema_version: #{schema_version}/g' .rcinfo`

	check_config_cmd = remote_cache_configuration.split(" ").map { |config| "--configuration #{config} "}.join("")
	check_platform_cmd = remote_cache_platform.split(" ").map { |config| "--platform #{config} "}.join("")

	if remote_cache_enable
	  ENV["COCOAPODS_LINK_POD_CACHE"] = 'false'
	  if remote_cache_mode == "consumer" || remote_cache_mode == 'producer-fast' #这两种模式需要请求一下服务，检查是否有缓存
		xcparepare_md5 = "daadef22d3bfa162bbe32a5694aa1e97"
	    if !File.exists?("XCRC/xcprepare") or `md5 -q XCRC/xcprepare`.strip != xcparepare_md5
			if !File.exists?(".xctemp/xcprepare") or `md5 -q .xctemp/xcprepare`.strip != xcparepare_md5
				`curl http://tosv.byted.org/obj/ee-infra-ios/xcrc/112/xcprepare --output .xctemp/xcprepare --create-dirs`
				`chmod +x .xctemp/xcprepare`
		    end
		  	prepare_cmd = ".xctemp/xcprepare #{check_config_cmd} #{check_platform_cmd}"
	    else          
			prepare_cmd = "./XCRC/xcprepare #{check_config_cmd} #{check_platform_cmd}"
	    end
		puts prepare_cmd
		prepare_result = `#{prepare_cmd}`
	    puts prepare_result
	    remote_cache_exists = prepare_result.include? "result: true"
	    if !remote_cache_exists
	      if remote_cache_mode == "consumer" 
	        #consumer模式，如果远端没有缓存，直接关闭远端缓存
	        remote_cache_enable = false
	      elsif remote_cache_mode == "producer-fast"
	        #producer模式，如果远端没有缓存，则使用producer模式构建
	        remote_cache_mode = "producer"
	      end
	    end
	  end

	  if remote_cache_enable
	    puts "开启远端缓存 模式为#{remote_cache_mode}"
	    plugin 'cocoapods-xcremotecache'
	    if remote_cache_mode == "producer" || remote_cache_mode == "producer-fast" #生产者模式，使用源码
		    ENV["USE_SWIFT_BINARY"] = "false"
	    end
		if ((ENV["template_config_id"] || "") != "132") && $lark_env.ci? 
			ENV["USE_SWIFT_BINARY"] = "false"
		end
	    repo_md5 = "/" + `md5 -qs #{scheme_tag}`[0...-1]
	    xcremotecache({
	      'cache_addresses' => ['http://build-larkmobile-boe.bytedance.net/cache'],
	      'primary_repo' => "git@code.byted.org:lark/iOS-client.git",
	      'primary_branch' => primary_branch,
	      'mode' => remote_cache_mode,
	      'final_target' => final_target,
	      'enabled' => remote_cache_enable,
	      'custom_rewrite_envs' => ['PODS_TARGET_SRCROOT'],
		  'cache_commit_history' => 20,
	      'custom_asset_url' => 'http://tosv.byted.org/obj/ee-infra-ios/xcrc/112/package.zip',
	      'irrelevant_dependencies_paths' => irrelevant_dependencies_paths,
	      'fake_src_root' => repo_md5,
	      'exclude_targets' => exclude_targets + ['RustSDK.default-LocalDev'],
		  'custom_fingerprint_envs' => custom_fingerprint_envs,
	      'schema_version' => schema_version,
	      'check_build_configuration' => remote_cache_configuration,
	      'check_platform' => check_platform_cmd.delete_prefix("--platform "),
		  'lldb_init_file_path' => 'LLDBInitFile',
		  'skip_user_target' => 'true',
		  'debug_prefix_map_replacement' => `git rev-parse --show-toplevel`.strip(),
		  'ignore_external_subspec_change' => ignore_external_subspec_change
	    })
	  else
	    puts "远端没有编译缓存，关闭远程缓存"
	    remote_cache_enable = false
	  end
	end
	if $lark_env.ci?
		puts `cat .rcinfo || true`
	end
	ENV["REMOTE_CACHE_ENABLE"] = remote_cache_enable.to_s

    hummer_tags["REMOTE_CACHE"] = remote_cache_enable ? true : false
    hummer_tags["REMOTE_CACHE_TEST"] = (ENV["REMOTE_CACHE_TEST"] == "true") ? true : false
    hummer_tags["Lark_BUILD_PACKAGE"] = (ENV["Lark_BUILD_PACKAGE"] == "true") ? true : false

	remote_cache_enabled = File.exists?(".rc/.rcinfo") and (`cat .rc/.rcinfo`.strip.length > 0)
	ENV["REMOTE_CACHE_CHANGED"] = ((last_time_remote_cache_enabled && !remote_cache_enable) or (!last_time_remote_cache_enabled && remote_cache_enable)).to_s
	remote_cache_enable
end

def clean_lldbinit(lldbinit_path)
	all_lines = []
	return all_lines unless File.exist?(lldbinit_path)
	File.open(lldbinit_path) { |file|
	  while(line = file.gets) != nil
		line = line.strip
		if line == "#RemoteCacheCustomSourceMap" 
		  # skip current and next lines
		  file.gets
		  next
		end
		all_lines << line
	  end
	}
	all_lines
  end
