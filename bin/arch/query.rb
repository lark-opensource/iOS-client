# frozen_string_literal: true

require_relative './query/query'

unless $main
  $main = true

  def print_usage(code)
    $stdout.puts <<~USAGE
      使用文档: https://bytedance.feishu.cn/docx/H7jHd01lHoJmaSxlAMhcdPz6nrb

      \e[32mUsage: #{$0} [options]\e[0m

      enter interactive repl for query deps

      \e[1mOptions:\e[0m
      -p: use pry as repl shell
      -r: use irb as repl shell (default)
      -e query: oneshot cmd to eval query. eg: RO("LarkAccount")
      -f file: eval cmd in file, and print the return value

      \e[32mUsage: #{$0} [I|O|IE|OE|RI|RO] name*\e[0m

      one shot query for incoming|outgoing pods or edges
    USAGE
    exit code
    # TODO: 直接运行命令输出依赖, 不进入repl模式
    # 直接输出需要没有多余输出。现在要加载Podfile里的group，需要改造成不依赖Podfile的
  end

  def output_query(action, query)
    repl = Query.create_from_lockfile
    puts repl.send(action, query).to_a
  end

  def main(argv)
    print_usage(0) if %w[-h --help].any? { |w| argv.include? w }
    case argv[0]&.upcase
    when 'I' then return output_query(:I, argv[1..])
    when 'O' then return output_query(:O, argv[1..])
    when 'IE' then return output_query(:IE, argv[1..])
    when 'OE' then return output_query(:OE, argv[1..])
    when 'RI' then return output_query(:RI, argv[1..])
    when 'RO' then return output_query(:RO, argv[1..])
    end

    require 'optparse'
    options = {}
    begin
      OptionParser.new do |opts|
        opts.on('-p')
        opts.on('-r')
        opts.on('-e query')
        opts.on('-f file')
      end.parse(argv, into: options)
    rescue
      puts $!.message, "\n"
      print_usage(-1)
    end

    query = Query.create_from_lockfile
    if q = options[:e]
      v = query.instance_eval q
      v = v.to_a if v.is_a?(Enumerable)
      return puts v
    end
    if f = options[:f]
      buffer = File.read(f)
      v = query.instance_eval buffer, f
      return if v.nil?
      v = v.to_a if v.is_a?(Enumerable)
      return puts v
    end

    puts <<~DOC
      使用文档: https://bytedance.feishu.cn/docx/H7jHd01lHoJmaSxlAMhcdPz6nrb
      示例:
        O('LarkChat')                  # 输出LarkChat的依赖
        I(root 'LarkAccountInterface') # 输出依赖AccountInterface(包含依赖subspec)的类
        V(root 'CCMMod').RO            # 输出CCMMod的全部递归依赖(使用V封装节点集合，可以使用链式语法)

        # ByteView业务层对平台层的依赖Edge.
        # V可以传入block过滤id. self和各种输出集合类型可以使用集合的各种方法
        # Edge可以通过`S`获取使用方，`T`获取被使用方
        # A可以把id转换为对象，可以访问config/arch里配置的属性等等
        # ruby3 可以使用_1的匿名参数
        V { v = A(_1); v.layer=="biz" and v.biz=="byteview" }.OE
          .select {|e| v = A(e.T); v.layer == 'platform' }

    DOC
    if options[:p]
      query.repl_pry
    else
      query.repl_irb
    end
  end

  main ARGV
end
