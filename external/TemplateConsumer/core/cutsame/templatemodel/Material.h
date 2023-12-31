//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "PlatformEnum.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Material {
        public:
        Material();
        virtual ~Material();

        private:
        std::string id;
        PlatformEnum platform;
        std::string type;

        public:
        const std::string & get_id() const;
        std::string & get_mut_id();
        void set_id(const std::string & value) ;

        const PlatformEnum & get_platform() const;
        PlatformEnum & get_mut_platform();
        void set_platform(const PlatformEnum & value) ;

        const std::string & get_type() const;
        std::string & get_mut_type();
        void set_type(const std::string & value) ;
    };
}
