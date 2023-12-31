# frozen_string_literal: true

RSpec.describe 'main' do
  it 'can run and syntax ok' do

    $main.send(:git_root)
    `exit 0` # set $?

    allow_any_instance_of(Object).to receive(:system)
    allow_any_instance_of(Object).to receive(:`).and_return ''
    allow_any_instance_of(Object).to receive(:puts)
    allow(IO).to receive(:popen) { |*_args, &block| block ? block.(StringIO.new) : '' }
    # allow(app).to receive(:system)

    allow($main).to receive(:print_usage)
    allow($main).to receive(:check_and_install_deps)
    allow($main).to receive(:gem_deps)
    app = App.new
    allow(App).to receive(:new).and_return(app)

    # group output
    $main.send :main, %w[-fgroup -g!AAA -i!xxx --show-exception]

    # ci output
    ENV['WORKFLOW_REPO_TARGET_BRANCH'] ||= '@'
    allow_any_instance_of(App::CIFormatter).to receive(:checked_files).and_return ['Modules/Messenger/aaa/bb/c.swift']
    original_grep_files = app.method(:grep_files)
    allow(app).to receive(:grep_files) {
      original_grep_files.()
      ['Modules/Messenger/aaa/bb/c.swift']
    }
    $main.send :main, %w[-fci Modules]
  end
end
