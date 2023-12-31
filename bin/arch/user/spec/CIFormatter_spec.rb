# frozen_string_literal: true

RSpec.describe App::CIFormatter do
  it 'can list checked files' do
    f = described_class.new
    allow(f).to receive(:ci_config)
      .and_return({ 'includePath' => ['Modules/Messenger/'],
                    'excludePath' => ['Modules/Messenger/Bizs/LarkSearch/'] })
    allow(f).to receive(:target_commit).and_return('@')
    allow(f).to receive(:`).and_return(<<~FILES)
      Modules/Messenger/aaa/bb/c.swift
      Modules/Messenger/Bizs/LarkSearch/lib/a.swift
      Modules/Other/Bizs/LarkSearch/lib/a.swift
    FILES
    expect(f.checked_files).to eq(['Modules/Messenger/aaa/bb/c.swift'])
  end
end
