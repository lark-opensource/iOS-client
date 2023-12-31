//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Crop {
        public:
        Crop();
        virtual ~Crop();

        private:
        double lower_left_x;
        double lower_left_y;
        double lower_right_x;
        double lower_right_y;
        double upper_left_x;
        double upper_left_y;
        double upper_right_x;
        double upper_right_y;

        public:
        const double & get_lower_left_x() const;
        double & get_mut_lower_left_x();
        void set_lower_left_x(const double & value) ;

        const double & get_lower_left_y() const;
        double & get_mut_lower_left_y();
        void set_lower_left_y(const double & value) ;

        const double & get_lower_right_x() const;
        double & get_mut_lower_right_x();
        void set_lower_right_x(const double & value) ;

        const double & get_lower_right_y() const;
        double & get_mut_lower_right_y();
        void set_lower_right_y(const double & value) ;

        const double & get_upper_left_x() const;
        double & get_mut_upper_left_x();
        void set_upper_left_x(const double & value) ;

        const double & get_upper_left_y() const;
        double & get_mut_upper_left_y();
        void set_upper_left_y(const double & value) ;

        const double & get_upper_right_x() const;
        double & get_mut_upper_right_x();
        void set_upper_right_x(const double & value) ;

        const double & get_upper_right_y() const;
        double & get_mut_upper_right_y();
        void set_upper_right_y(const double & value) ;
    };
}
