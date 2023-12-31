//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "PlatformEnum.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MutableMaterial {
        public:
        MutableMaterial();
        virtual ~MutableMaterial();

        private:
        std::string cover_path;
        std::string id;
        PlatformEnum platform;
        std::string relation_video_group;

        public:
        const std::string & get_cover_path() const;
        std::string & get_mut_cover_path();
        void set_cover_path(const std::string & value) ;

        const std::string & get_id() const;
        std::string & get_mut_id();
        void set_id(const std::string & value) ;

        const PlatformEnum & get_platform() const;
        PlatformEnum & get_mut_platform();
        void set_platform(const PlatformEnum & value) ;

        const std::string & get_relation_video_group() const;
        std::string & get_mut_relation_video_group();
        void set_relation_video_group(const std::string & value) ;
    };
}
