//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Stable {
        public:
        Stable();
        virtual ~Stable();

        private:
        std::string matrix_path;
        int64_t stable_level;

        public:
        const std::string & get_matrix_path() const;
        std::string & get_mut_matrix_path();
        void set_matrix_path(const std::string & value) ;

        const int64_t & get_stable_level() const;
        int64_t & get_mut_stable_level();
        void set_stable_level(const int64_t & value) ;
    };
}
