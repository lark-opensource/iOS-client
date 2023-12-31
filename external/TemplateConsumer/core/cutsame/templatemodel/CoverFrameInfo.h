//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class CoverFrameInfo {
        public:
        CoverFrameInfo();
        virtual ~CoverFrameInfo();

        private:
        int64_t position;
        std::string segment_id;

        public:
        const int64_t & get_position() const;
        int64_t & get_mut_position();
        void set_position(const int64_t & value) ;

        const std::string & get_segment_id() const;
        std::string & get_mut_segment_id();
        void set_segment_id(const std::string & value) ;
    };
}
