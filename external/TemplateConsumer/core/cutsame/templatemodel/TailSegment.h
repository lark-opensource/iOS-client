//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class TailSegment {
        public:
        TailSegment();
        virtual ~TailSegment();

        private:
        std::string material_id;
        int64_t target_start_time;
        std::string text;

        public:
        const std::string & get_material_id() const;
        std::string & get_mut_material_id();
        void set_material_id(const std::string & value) ;

        const int64_t & get_target_start_time() const;
        int64_t & get_mut_target_start_time();
        void set_target_start_time(const int64_t & value) ;

        const std::string & get_text() const;
        std::string & get_mut_text();
        void set_text(const std::string & value) ;
    };
}
