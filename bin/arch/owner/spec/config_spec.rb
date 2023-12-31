module OwnerConfig

  RSpec.describe PodsConfig do
    describe '#initialize' do
      context 'with non-hash parameter' do
        it 'can raise error' do
          expect {
            described_class.new('', [])
          }.to raise_error(OwnerConfigParseError, /Config should be hash, but got:/)
        end
      end

      context 'with invalid parameter structure' do
        it 'can raise error' do
          expect {
            described_class.new('', {})
          }.to raise_error(OwnerConfigParseError, 'Config should include ATTRS')

          expect {
            described_class.new('', { 'ATTRS' => {} })
          }.to raise_error(OwnerConfigParseError, 'Config ATTRS should include $TEAM')

          expect {
            described_class.new('', { 'ATTRS' => { '$TEAM' => [] } })
          }.to raise_error(OwnerConfigParseError, /Config should include PODS as hash, but got:/)
        end
      end

      context 'with invalid pod config' do
        it 'can raise error with pod name' do
          expect {
            described_class.new(
              '',
              {
                'ATTRS' => { '$TEAM' => [] },
                'PODS' => {
                  'PodA' => { 'team' => 'Team1', 'owners' => [] },
                  'PodB' => {}
                }
              })
          }.to raise_error(OwnerConfigParseError, /The config of pod \w+ is invalid, config: .*, reason: .*/)
        end
      end
    end

    # describe '#add_pod!' do
    #   context 'with empty config_path' do
    #     it 'can raise error' do
    #       instance = described_class.new(
    #         '',
    #         {
    #           'ATTRS' => { '$TEAM' => [] },
    #           'PODS' => {
    #             'PodA' => { 'team' => 'Team1', 'owners' => [] }
    #           }
    #         })
    #       expect {
    #         instance.add_pod!(name: "", owners: [])
    #       }.to raise_error(OwnerConfigParseError, 'config_path should not be empty when adding a pod')
    #     end
    #   end
    #
    #   context 'with valid file' do
    #     before(:example) do
    #       # copy template file for mock
    #       template_path = File.join(__dir__, 'mock/test_for_add_pod_template.yml')
    #       generated_path = File.join(__dir__, 'mock/generated/test_for_add_pod.yml')
    #       FileUtils.mkdir_p(File.dirname(generated_path))
    #       FileUtils.cp(template_path, generated_path)
    #     end
    #
    #     it 'can add new pod' do
    #       mock_path = File.join(__dir__, 'mock/generated/test_for_add_pod.yml')
    #       expect_path = File.join(__dir__, 'mock/test_for_add_pod_expect.yml')
    #
    #       described_class.load_file(mock_path)
    #                      .add_pod!(
    #                        name: 'PodB',
    #                        owners: ['Owner2']
    #                      )
    #       expect(File.read(mock_path)).to eq(File.read(expect_path))
    #     end
    #   end
    # end

    describe '.load_file' do
      context 'with empty file' do
        it 'can raise error' do
          mock_path = File.join(__dir__, 'mock/empty_config.yml')

          expect {
            described_class.load_file(mock_path)
          }.to raise_error(OwnerConfigParseError, 'Could not load config from empty YAML file')
        end
      end
    end
  end

  RSpec.describe ExtraConfig::Rule do
    describe '#initialize' do
      context 'with non-hash parameter' do
        it 'can raise error' do
          expect {
            described_class.new([])
          }.to raise_error(OwnerConfigParseError, /Rule should be hash, but got:/)
        end
      end

      context 'with invalid parameter structure' do
        it 'can raise error' do
          expect {
            described_class.new({})
          }.to raise_error(OwnerConfigParseError, 'Rule should include mode')

          expect {
            described_class.new({ 'mode' => 'catalog' })
          }.to raise_error(OwnerConfigParseError, 'Catalog rule should include prefix')

          expect {
            described_class.new({ 'mode' => 'catalog', 'prefix' => 'prefix' })
          }.to raise_error(OwnerConfigParseError, 'Catalog rule should include sub-rules')

          expect {
            described_class.new({ 'mode' => 'path' })
          }.to raise_error(OwnerConfigParseError, 'Non-catalog rule should include pattern')

          expect {
            described_class.new({ 'mode' => 'path', 'pattern' => 'pattern' })
          }.to raise_error(OwnerConfigParseError, 'Non-catalog rule should include owners')
        end
      end
    end
  end

  RSpec.describe ExtraConfig do
    describe '#initialize' do
      context 'with non-hash parameter' do
        it 'can raise error' do
          expect {
            described_class.new([])
          }.to raise_error(OwnerConfigParseError, /Config should be hash, but got:/)
        end
      end

      context 'with invalid parameter structure' do
        it 'can raise error' do
          expect {
            described_class.new({ 'RULES' => {} })
          }.to raise_error(OwnerConfigParseError, /Config should include rules as array, but got:/)
        end
      end

      context 'with invalid rule config' do
        it 'can raise error with config value' do
          expect {
            described_class.new({ 'RULES' => ['mode' => 'path'] })
          }.to raise_error(OwnerConfigParseError, /The rule config is invalid, config: .*, reason: .*/)
        end
      end
    end

    describe '#flattened_pattern_to_rule' do
      context 'with one-level nesting' do
        it 'can return correct' do
          instance = described_class.new(
            {
              'RULES' => [
                { 'mode' => 'path', 'pattern' => 'path', 'owners' => [] },
                { 'mode' => 'regex', 'pattern' => 'regex', 'owners' => [] },
              ]
            })

          expect(instance.flattened_pattern_to_rule.values).to eq instance.rules
        end
      end

      context 'with nesting rules' do
        it 'can return correct' do
          instance = described_class.new(
            {
              'RULES' => [
                { 'mode' => 'path', 'pattern' => 'path1', 'owners' => [] },
                { 'mode' => 'catalog', 'prefix' => 'prefix/', 'rules' => [
                  { 'mode' => 'path', 'pattern' => 'path2', 'owners' => [] },
                  { 'mode' => 'regex', 'pattern' => 'regex', 'owners' => [] },
                ] },
              ]
            })

          actual_rules = instance.flattened_pattern_to_rule
                                 .transform_values { |rule| rule.to_h }
          expected_rules = {
            'path1' => { 'mode' => 'path', 'pattern' => 'path1', 'owners' => [], 'required_approvals' => 1 },
            'prefix/path2' => { 'mode' => 'path', 'pattern' => 'path2', 'owners' => [], 'required_approvals' => 1 },
            'prefix/regex' => { 'mode' => 'regex', 'pattern' => 'regex', 'owners' => [], 'required_approvals' => 1 },
          }
          expect(actual_rules).to eq(expected_rules)
        end
      end
    end

    describe '.load_file' do
      context 'with empty file' do
        it 'can raise error' do
          mock_path = File.join(__dir__, 'mock/empty_config.yml')

          expect {
            described_class.load_file(mock_path)
          }.to raise_error(OwnerConfigParseError, 'Could not load config from empty YAML file')
        end
      end

      context 'with invalid YAML text' do
        it 'can raise error' do
          mock_path = File.join(__dir__, 'mock/invalid_yaml_format.yml')

          expect {
            described_class.load_file(mock_path)
          }.to raise_error(OwnerConfigParseError, /YAML parse error:/)
        end
      end
    end
  end
end
