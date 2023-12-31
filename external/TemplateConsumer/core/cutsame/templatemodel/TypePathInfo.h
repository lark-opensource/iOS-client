//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class TypePathInfo {
        public:
        TypePathInfo();
        virtual ~TypePathInfo();

        private:
        std::string path;
        std::vector<int64_t> type;

        public:
        const std::string & get_path() const;
        std::string & get_mut_path();
        void set_path(const std::string & value) ;

        const std::vector<int64_t> & get_type() const;
        std::vector<int64_t> & get_mut_type();
        void set_type(const std::vector<int64_t> & value) ;
    };
}
