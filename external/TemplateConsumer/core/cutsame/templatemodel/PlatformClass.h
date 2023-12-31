//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class PlatformClass {
        public:
        PlatformClass();
        virtual ~PlatformClass();

        private:
        std::string app_version;
        std::string os;
        std::string os_version;

        public:
        const std::string & get_app_version() const;
        std::string & get_mut_app_version();
        void set_app_version(const std::string & value) ;

        const std::string & get_os() const;
        std::string & get_mut_os();
        void set_os(const std::string & value) ;

        const std::string & get_os_version() const;
        std::string & get_mut_os_version();
        void set_os_version(const std::string & value) ;
    };
}
