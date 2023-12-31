//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class Flip;
    class Point;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Clip {
        public:
        Clip();
        virtual ~Clip();

        private:
        double alpha;
        std::shared_ptr<Flip> flip;
        double rotation;
        std::shared_ptr<Point> scale;
        std::shared_ptr<Point> transform;

        public:
        const double & get_alpha() const;
        double & get_mut_alpha();
        void set_alpha(const double & value) ;

        const std::shared_ptr<Flip> & get_flip() const;
        std::shared_ptr<Flip> & get_mut_flip();
        void set_flip(const std::shared_ptr<Flip> & value) ;

        const double & get_rotation() const;
        double & get_mut_rotation();
        void set_rotation(const double & value) ;

        const std::shared_ptr<Point> & get_scale() const;
        std::shared_ptr<Point> & get_mut_scale();
        void set_scale(const std::shared_ptr<Point> & value) ;

        const std::shared_ptr<Point> & get_transform() const;
        std::shared_ptr<Point> & get_mut_transform();
        void set_transform(const std::shared_ptr<Point> & value) ;
    };
}
