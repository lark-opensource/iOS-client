# frozen_string_literal: true

RSpec.describe 'task' do
  before(:each) do
    $main.send(:git_root)
    `exit 0` # set $?
  end
  let(:app) { App.new }
  let(:config) {
    {
      'excludePath' => [],
      'globalType' => %w[AAA]
    }
  }
  def stub_grep_result(string)
    allow(IO).to receive(:popen) do |*args, &block|
      if args.size >= 2 and args[1].is_a? Array and args[1][1] == '--vimgrep'
        io = StringIO.new(string)
        next block ? block.(io) : io
      end
      next block ? block.(StringIO.new) : ''
    end
  end
  it 'can check force_resolve' do
    app.parse! %w[-fvim -iforce_resolve], config

    stub_grep_result(<<~VIM)
      a.swift:10:5: Container.shared.resolve(AAA.self)
      a.swift:11:5: r.resolve(BBB.self)
    VIM

    expect { app.run! }.to output(<<~OUT).to_stdout
      # check force resolve api
      a.swift:11:5: r.resolve(BBB.self)
      [WARNING]请使用resolve(assert:), 并处理相关异常，避免强解包
    OUT
  end
  it 'can check global_resolve' do
    app.parse! %w[-fvim -iglobal_resolve], config

    stub_grep_result(<<~VIM)
      a.swift:10:5: Container.shared.resolve(AAA.self)
      a.swift:10:5: Container.shared.resolve(BBB.self)
      a.swift:12:5: @Inject var xxcvz: AAA
      a.swift:12:5: @Inject var xxcvz: BBB
    VIM

    expect { app.run! }.to output(<<~OUT).to_stdout
      # check global_resolve usage
      a.swift:10:5: Container.shared.resolve(BBB.self)
      a.swift:12:5: @Inject var xxcvz: BBB
      [WARNING]只有用户无关服务可以使用, 请检查以上调用是否符合预期
    OUT
  end
end
