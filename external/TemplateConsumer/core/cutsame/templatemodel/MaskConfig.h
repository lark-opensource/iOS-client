//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaskConfig {
        public:
        MaskConfig();
        virtual ~MaskConfig();

        private:
        double aspect_ratio;
        double center_x;
        double center_y;
        double feather;
        double height;
        bool invert;
        double rotation;
        double round_corner;
        double width;

        public:
        const double & get_aspect_ratio() const;
        double & get_mut_aspect_ratio();
        void set_aspect_ratio(const double & value) ;

        const double & get_center_x() const;
        double & get_mut_center_x();
        void set_center_x(const double & value) ;

        const double & get_center_y() const;
        double & get_mut_center_y();
        void set_center_y(const double & value) ;

        const double & get_feather() const;
        double & get_mut_feather();
        void set_feather(const double & value) ;

        const double & get_height() const;
        double & get_mut_height();
        void set_height(const double & value) ;

        const bool & get_invert() const;
        bool & get_mut_invert();
        void set_invert(const bool & value) ;

        const double & get_rotation() const;
        double & get_mut_rotation();
        void set_rotation(const double & value) ;

        const double & get_round_corner() const;
        double & get_mut_round_corner();
        void set_round_corner(const double & value) ;

        const double & get_width() const;
        double & get_mut_width();
        void set_width(const double & value) ;
    };
}
