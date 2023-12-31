require 'json'

# Define some constants

mock_prefix = '/iOS-client/'
mock_open_combine_prefix = 'Modules/Infra/Libs/Combine/OpenCombine/Sources/'

special_mock = {
  'LarkOpenCombine' => mock_prefix + mock_open_combine_prefix + 'OpenCombine/',
  'LarkOpenCombineDispatch' => mock_prefix + mock_open_combine_prefix + 'OpenCombineDispatch/',
  'LarkOpenCombineFoundation' => mock_prefix + mock_open_combine_prefix + 'OpenCombineFoundation/'
}

ignore_modules = [
  'SKFoundation_Tests'
]

# Read json data

modules_array = JSON.parse File.read '../../modules.json'
path_config_array = JSON.parse File.read './path_config.json'

# Create an array of zeros with length equal to the length of the path_config_array
config_counter = [0] * path_config_array.length

modules_array.each do |mod|
  raise 'unexpected error' unless mod['components'].size == 1

  mod_path = mod['path']
  mod_component = mod['components'][0]

  next if ignore_modules.include? mod_component

  default_mock_path = mock_prefix + mod_path
  mock_path = special_mock.fetch mod_component, default_mock_path

  puts '[module] %s has not been matched, path: %s' % [
    mod_component, mod_path
  ] unless path_config_array.each_with_index.any? do |config, index|
    regexp = config['regexp']
    regex = Regexp.new regexp
    path_index = config['path_index']
    component_index = config['component_index']

    if (result = regex.match mock_path)
      path = path_index == -1 ? config['path'] : result[path_index]
      component = component_index == -1 ? config['component'] : result[component_index]

      if path.start_with? mod_path
        if component == mod_component
          config_counter[index] += 1
        else
          puts '[regex] %s uses wrong regex: %s, result: %s, path: %s' % [mod_component, regexp, component, path]
        end
        break true
      end
    end
    next false
  end
end

config_counter.each_with_index
              .select { |x, _| x.zero? }
              .map { |_, i| path_config_array[i]['regexp'] }
              .each { |regexp| puts '[regex] %s has not matched any module' % [regexp] }
