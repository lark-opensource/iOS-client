//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class DependencyResource {
        public:
        DependencyResource();
        virtual ~DependencyResource();

        private:
        std::string path;
        std::string resource_id;

        public:
        const std::string & get_path() const;
        std::string & get_mut_path();
        void set_path(const std::string & value) ;

        const std::string & get_resource_id() const;
        std::string & get_mut_resource_id();
        void set_resource_id(const std::string & value) ;
    };
}
