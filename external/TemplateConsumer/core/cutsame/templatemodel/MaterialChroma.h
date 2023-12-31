//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialChroma : public Material {
        public:
        MaterialChroma();
        virtual ~MaterialChroma();

        private:
        std::string color;
        double intensity_value;
        std::string path;
        double shadow_value;

        public:
        const std::string & get_color() const;
        std::string & get_mut_color();
        void set_color(const std::string & value) ;

        const double & get_intensity_value() const;
        double & get_mut_intensity_value();
        void set_intensity_value(const double & value) ;

        const std::string & get_path() const;
        std::string & get_mut_path();
        void set_path(const std::string & value) ;

        const double & get_shadow_value() const;
        double & get_mut_shadow_value();
        void set_shadow_value(const double & value) ;
    };
}
