require 'json'

class RtcBuildConfig
    @@is_xcode_13_3 = false
    @@current_dir = File.dirname(__FILE__)
    @@submodules = []

    def self.get_submodules
        @@submodules
    end

    def self.set_submodules(modules)
        @@submodules = modules
    end

    def self.set_xcode_133(is_xcode_13_3)
        @@is_xcode_13_3 = is_xcode_13_3
    end

    def self.current_dir
        return @@current_dir
    end

    def self.rtc_dirname
        return 'ByteRTC'
    end

    def self.rtc_root
        return "#{self.current_dir}/#{self.rtc_dirname}"
    end

    def self.realx_root
        return self.rtc_root
    end

    def self.build_root
        return "#{self.rtc_root}/build_ios/podspec"
    end

    def self.third_party_dir
        return "#{self.current_dir}/third_party"
    end

    def self.cmake_file(target)
        return Dir.glob("#{self.build_root}/.cmake/api/v1/reply/target-#{target}-Release-*").first
    end

    def self.all_cmake_files
        return Dir.glob("#{self.build_root}/.cmake/api/v1/reply/target-*-Release-*")
    end

    def self.cmake_configs(target)
        return JSON.parse(File.read(self.cmake_file(target)))
    end

    def self.realx_common_flags(is_cflag)
        flags = []
        if is_cflag
            flags += ["-fstrict-aliasing", "'-fvisibility=hidden'"]
        else
            flags += ["-fno-c++-static-destructors", "'-fvisibility=hidden'", "-fvisibility-inlines-hidden"]
        end
        flags += [
        "-Wall",
        "-Wextra",
        "-Wno-unused-parameter",
        "-Wno-conversion",
        "-Wno-multichar",
        "-DNDEBUG",
        "-fPIC",
        "-Wthread-safety",
        "-fcolor-diagnostics",
        "-Werror",
        "-Wno-sign-compare",
        "-Wno-range-loop-analysis",
        "-Wno-missing-braces",
        "'-Wno-error=deprecated-declarations'",
        "'-Wno-error=thread-safety-analysis'",
        "'-Wno-error=unused-function'",
        "'-Wno-error=unused-private-field'",
        "'-Wno-error=unused-variable'",
        "'-Wno-error=missing-field-initializers'",
        "'-Wno-error=overloaded-virtual'",
        ]
        if @@is_xcode_13_3
            flags += [
            "'-Wno-error=unused-but-set-variable'",
            "'-Wno-error=unused-but-set-parameter'",
            "'-Wno-error=deprecated-copy'",
            ]
        end
        flags += ["-Wglobal-constructors"]
        if is_cflag
            flags += ["$(inherited)"]
        else
            flags += ["-fexceptions", "-fno-rtti", "'-std=c++14'"]
        end
        return flags
    end

    def self.realx_cflags
        return self.realx_common_flags(true)
    end

    def self.realx_cxxflags
        return self.realx_common_flags(false)
    end
end
