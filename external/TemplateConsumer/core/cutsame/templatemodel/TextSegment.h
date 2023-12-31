//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class TextSegment {
        public:
        TextSegment();
        virtual ~TextSegment();

        private:
        int64_t duration;
        bool is_mutable;
        std::string material_id;
        double rotation;
        int64_t target_start_time;
        std::string text;

        public:
        const int64_t & get_duration() const;
        int64_t & get_mut_duration();
        void set_duration(const int64_t & value) ;

        const bool & get_is_mutable() const;
        bool & get_mut_is_mutable();
        void set_is_mutable(const bool & value) ;

        const std::string & get_material_id() const;
        std::string & get_mut_material_id();
        void set_material_id(const std::string & value) ;

        const double & get_rotation() const;
        double & get_mut_rotation();
        void set_rotation(const double & value) ;

        const int64_t & get_target_start_time() const;
        int64_t & get_mut_target_start_time();
        void set_target_start_time(const int64_t & value) ;

        const std::string & get_text() const;
        std::string & get_mut_text();
        void set_text(const std::string & value) ;
    };
}
