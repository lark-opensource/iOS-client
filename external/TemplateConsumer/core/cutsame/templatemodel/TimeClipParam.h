//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class TimeClipParam {
        public:
        TimeClipParam();
        virtual ~TimeClipParam();

        private:
        double speed;
        int64_t trim_in;
        int64_t trim_out;

        public:
        const double & get_speed() const;
        double & get_mut_speed();
        void set_speed(const double & value) ;

        const int64_t & get_trim_in() const;
        int64_t & get_mut_trim_in();
        void set_trim_in(const int64_t & value) ;

        const int64_t & get_trim_out() const;
        int64_t & get_mut_trim_out();
        void set_trim_out(const int64_t & value) ;
    };
}
