//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Point {
        public:
        Point();
        virtual ~Point();

        private:
        double x;
        double y;

        public:
        const double & get_x() const;
        double & get_mut_x();
        void set_x(const double & value) ;

        const double & get_y() const;
        double & get_mut_y();
        void set_y(const double & value) ;
    };
}
