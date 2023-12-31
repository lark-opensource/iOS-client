//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class UserDeleteAiBeats {
        public:
        UserDeleteAiBeats();
        virtual ~UserDeleteAiBeats();

        private:
        std::vector<int64_t> beat_0;
        std::vector<int64_t> beat_1;
        std::vector<int64_t> melody_0;

        public:
        const std::vector<int64_t> & get_beat_0() const;
        std::vector<int64_t> & get_mut_beat_0();
        void set_beat_0(const std::vector<int64_t> & value) ;

        const std::vector<int64_t> & get_beat_1() const;
        std::vector<int64_t> & get_mut_beat_1();
        void set_beat_1(const std::vector<int64_t> & value) ;

        const std::vector<int64_t> & get_melody_0() const;
        std::vector<int64_t> & get_mut_melody_0();
        void set_melody_0(const std::vector<int64_t> & value) ;
    };
}
