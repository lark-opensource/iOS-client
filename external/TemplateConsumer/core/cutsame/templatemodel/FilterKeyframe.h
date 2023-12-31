//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Keyframe.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class FilterKeyframe : public Keyframe {
        public:
        FilterKeyframe();
        virtual ~FilterKeyframe();

        private:
        double value;

        public:
        const double & get_value() const;
        double & get_mut_value();
        void set_value(const double & value) ;
    };
}
