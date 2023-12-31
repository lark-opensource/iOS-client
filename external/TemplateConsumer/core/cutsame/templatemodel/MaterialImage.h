//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialImage : public Material {
        public:
        MaterialImage();
        virtual ~MaterialImage();

        private:
        int64_t height;
        double initial_scale;
        std::string path;
        int64_t width;

        public:
        const int64_t & get_height() const;
        int64_t & get_mut_height();
        void set_height(const int64_t & value) ;

        const double & get_initial_scale() const;
        double & get_mut_initial_scale();
        void set_initial_scale(const double & value) ;

        const std::string & get_path() const;
        std::string & get_mut_path();
        void set_path(const std::string & value) ;

        const int64_t & get_width() const;
        int64_t & get_mut_width();
        void set_width(const int64_t & value) ;
    };
}
