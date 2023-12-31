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
    class TextKeyframe : public Keyframe {
        public:
        TextKeyframe();
        virtual ~TextKeyframe();

        private:
        double background_alpha;
        std::string background_color;
        std::string border_color;
        double border_width;
        std::shared_ptr<Point> position;
        double rotation;
        std::shared_ptr<Point> scale;
        double shadow_alpha;
        double shadow_angle;
        std::string shadow_color;
        std::shared_ptr<Point> shadow_point;
        double shadow_smoothing;
        double text_alpha;
        std::string text_color;

        public:
        const double & get_background_alpha() const;
        double & get_mut_background_alpha();
        void set_background_alpha(const double & value) ;

        const std::string & get_background_color() const;
        std::string & get_mut_background_color();
        void set_background_color(const std::string & value) ;

        const std::string & get_border_color() const;
        std::string & get_mut_border_color();
        void set_border_color(const std::string & value) ;

        const double & get_border_width() const;
        double & get_mut_border_width();
        void set_border_width(const double & value) ;

        const std::shared_ptr<Point> & get_position() const;
        std::shared_ptr<Point> & get_mut_position();
        void set_position(const std::shared_ptr<Point> & value) ;

        const double & get_rotation() const;
        double & get_mut_rotation();
        void set_rotation(const double & value) ;

        const std::shared_ptr<Point> & get_scale() const;
        std::shared_ptr<Point> & get_mut_scale();
        void set_scale(const std::shared_ptr<Point> & value) ;

        const double & get_shadow_alpha() const;
        double & get_mut_shadow_alpha();
        void set_shadow_alpha(const double & value) ;

        const double & get_shadow_angle() const;
        double & get_mut_shadow_angle();
        void set_shadow_angle(const double & value) ;

        const std::string & get_shadow_color() const;
        std::string & get_mut_shadow_color();
        void set_shadow_color(const std::string & value) ;

        const std::shared_ptr<Point> & get_shadow_point() const;
        std::shared_ptr<Point> & get_mut_shadow_point();
        void set_shadow_point(const std::shared_ptr<Point> & value) ;

        const double & get_shadow_smoothing() const;
        double & get_mut_shadow_smoothing();
        void set_shadow_smoothing(const double & value) ;

        const double & get_text_alpha() const;
        double & get_mut_text_alpha();
        void set_text_alpha(const double & value) ;

        const std::string & get_text_color() const;
        std::string & get_mut_text_color();
        void set_text_color(const std::string & value) ;
    };
}
