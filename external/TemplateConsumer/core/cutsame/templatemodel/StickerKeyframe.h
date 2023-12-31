//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Keyframe.h"
namespace CutSame {
    class Point;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class StickerKeyframe : public Keyframe {
        public:
        StickerKeyframe();
        virtual ~StickerKeyframe();

        private:
        std::shared_ptr<Point> position;
        double rotation;
        std::shared_ptr<Point> scale;

        public:
        const std::shared_ptr<Point> & get_position() const;
        std::shared_ptr<Point> & get_mut_position();
        void set_position(const std::shared_ptr<Point> & value) ;

        const double & get_rotation() const;
        double & get_mut_rotation();
        void set_rotation(const double & value) ;

        const std::shared_ptr<Point> & get_scale() const;
        std::shared_ptr<Point> & get_mut_scale();
        void set_scale(const std::shared_ptr<Point> & value) ;
    };
}
