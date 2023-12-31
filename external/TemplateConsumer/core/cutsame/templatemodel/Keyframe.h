//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Keyframe {
        public:
        Keyframe();
        virtual ~Keyframe();

        private:
        std::string id;
        int64_t time_offset;
        std::string type;

        public:
        const std::string & get_id() const;
        std::string & get_mut_id();
        void set_id(const std::string & value) ;

        const int64_t & get_time_offset() const;
        int64_t & get_mut_time_offset();
        void set_time_offset(const int64_t & value) ;

        const std::string & get_type() const;
        std::string & get_mut_type();
        void set_type(const std::string & value) ;
    };
}
