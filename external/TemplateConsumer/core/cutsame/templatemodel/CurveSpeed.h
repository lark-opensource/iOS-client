//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class Point;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class CurveSpeed {
        public:
        CurveSpeed();
        virtual ~CurveSpeed();

        private:
        std::string id;
        std::string name;
        std::vector<std::shared_ptr<Point>> speed_points;

        public:
        const std::string & get_id() const;
        std::string & get_mut_id();
        void set_id(const std::string & value) ;

        const std::string & get_name() const;
        std::string & get_mut_name();
        void set_name(const std::string & value) ;

        const std::vector<std::shared_ptr<Point>> & get_speed_points() const;
        std::vector<std::shared_ptr<Point>> & get_mut_speed_points();
        void set_speed_points(const std::vector<std::shared_ptr<Point>> & value) ;
    };
}
