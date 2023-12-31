//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Timerange {
        public:
        Timerange();
        virtual ~Timerange();

        private:
        int64_t duration;
        int64_t start;

        public:
        const int64_t & get_duration() const;
        int64_t & get_mut_duration();
        void set_duration(const int64_t & value) ;

        const int64_t & get_start() const;
        int64_t & get_mut_start();
        void set_start(const int64_t & value) ;
    };
}
