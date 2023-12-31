//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialResource {
        public:
        MaterialResource();
        virtual ~MaterialResource();

        private:
        std::string panel;
        std::string path;
        std::string resource_id;
        int64_t source_platform;

        public:
        const std::string & get_panel() const;
        std::string & get_mut_panel();
        void set_panel(const std::string & value) ;

        const std::string & get_path() const;
        std::string & get_mut_path();
        void set_path(const std::string & value) ;

        const std::string & get_resource_id() const;
        std::string & get_mut_resource_id();
        void set_resource_id(const std::string & value) ;

        const int64_t & get_source_platform() const;
        int64_t & get_mut_source_platform();
        void set_source_platform(const int64_t & value) ;
    };
}
