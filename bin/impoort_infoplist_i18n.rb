# frozen_string_literal: true

require 'pathname'
require_relative '../fastlane/lib.rb'
require 'csv'

# @param data [Hash]
# @param path [Pathname]
def convert_to_dir(data, path, name, keys, mapper: {})
  rows = data.values_at(*keys).compact
  return if rows.empty?

  langs = rows.first.headers[1..-1].map { |h| h and v = h.strip and !v.empty? and v }.compact
  langs.each do |lang|
    to_lang = mapper[lang] || lang[0, 2]
    # @type [Pathname]
    p = path.join("#{to_lang}.lproj/#{name}.strings")
    p.parent.mkpath
    strings = Apple::Strings.load(p)
    rows.each do |row|
      strings[row[0]] = row[lang]
    end
    puts "will write #{p}"
    strings.write(p)
  end
end

def import(csv_path)
  data = CSV.read(csv_path, headers: true).map do |row|
    row[0].strip!
    [row[0], row]
  end.to_h

  root = Pathname(__dir__).parent
  Dir.chdir(root) do
    # rubocop:disable all
    convert_to_dir(data, root + 'Lark/Resources/Settings.bundle', 'Root', %w[
                   Lark_Login_Troubleshootingtitle
                   Lark_Login_Troubleshooting])
    convert_to_dir(data, root + 'Lark', 'InfoPlist', %w[
  CFBundleDisplayName
  NSBluetoothPeripheralUsageDescription NSBluetoothAlwaysUsageDescription
  NSLocationAlwaysUsageDescription NSLocationWhenInUseUsageDescription
  NSPhotoLibraryAddUsageDescription NSPhotoLibraryUsageDescription
  NSCameraUsageDescription NSMicrophoneUsageDescription NSContactsUsageDescription NSSpeechRecognitionUsageDescription
  NSCalendarsUsageDescription NSFaceIDUsageDescription NSMotionUsageDescription
    ], mapper: {
        "zh-CN" => "zh-Hans",
        "zh-HK" => "zh-HK",
        "zh-TW" => "zh-Hant-TW",
    })

    # add strings ref into xcodeproj
    require 'xcodeproj'
    project = Xcodeproj::Project.open('Lark.xcodeproj')
    # @type [Xcodeproj::Project::Object::PBXNativeTarget]
    group = project['Lark'].recursive_children.find do |g|
      g.is_a? Xcodeproj::Project::Object::PBXVariantGroup and g.name == 'InfoPlist.strings'
    end
    Dir.glob 'Lark/*.lproj/Infoplist.strings' do |strings_path|
      lang_code = Pathname(strings_path).parent.basename('.*').to_s
      if group and !group[lang_code]
        ref = group.new_file(File.expand_path(strings_path))
        ref.name = lang_code
      end
    end
    project.save if project.dirty?
    # rubocop:enable all
  end
end

if (path = ARGV[0])
  csv_path = File.expand_path(path)
  import(csv_path)
else
  puts <<~EOF
    #{$PROGRAM_NAME} <path_to_feishu_csv>
    convert script from feish csv format to the infoplist.strings and Settings.bundle
  EOF
end
