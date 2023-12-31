//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialCanvas : public Material {
        public:
        MaterialCanvas();
        virtual ~MaterialCanvas();

        private:
        std::string album_image;
        double blur;
        std::string color;
        std::string image;
        std::string image_id;
        std::string image_name;

        public:
        const std::string & get_album_image() const;
        std::string & get_mut_album_image();
        void set_album_image(const std::string & value) ;

        const double & get_blur() const;
        double & get_mut_blur();
        void set_blur(const double & value) ;

        const std::string & get_color() const;
        std::string & get_mut_color();
        void set_color(const std::string & value) ;

        const std::string & get_image() const;
        std::string & get_mut_image();
        void set_image(const std::string & value) ;

        const std::string & get_image_id() const;
        std::string & get_mut_image_id();
        void set_image_id(const std::string & value) ;

        const std::string & get_image_name() const;
        std::string & get_mut_image_name();
        void set_image_name(const std::string & value) ;
    };
}
