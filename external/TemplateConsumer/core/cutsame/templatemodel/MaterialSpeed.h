//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"
namespace CutSame {
    class CurveSpeed;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialSpeed : public Material {
        public:
        MaterialSpeed();
        virtual ~MaterialSpeed();

        private:
        std::shared_ptr<CurveSpeed> curve_speed;
        int64_t mode;
        double speed;

        public:
        const std::shared_ptr<CurveSpeed> & get_curve_speed() const;
        std::shared_ptr<CurveSpeed> & get_mut_curve_speed();
        void set_curve_speed(const std::shared_ptr<CurveSpeed> & value) ;

        const int64_t & get_mode() const;
        int64_t & get_mut_mode();
        void set_mode(const int64_t & value) ;

        const double & get_speed() const;
        double & get_mut_speed();
        void set_speed(const double & value) ;
    };
}
