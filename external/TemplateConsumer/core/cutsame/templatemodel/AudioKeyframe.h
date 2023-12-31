//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Keyframe.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class AudioKeyframe : public Keyframe {
        public:
        AudioKeyframe();
        virtual ~AudioKeyframe();

        private:
        double volume;

        public:
        const double & get_volume() const;
        double & get_mut_volume();
        void set_volume(const double & value) ;
    };
}
