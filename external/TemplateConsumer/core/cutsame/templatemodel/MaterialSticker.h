//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialSticker : public Material {
        public:
        MaterialSticker();
        virtual ~MaterialSticker();

        private:
        std::string category_id;
        std::string category_name;
        std::string icon_url;
        std::string name;
        std::string path;
        std::string preview_cover_url;
        std::string resource_id;
        int64_t source_platform;
        std::string sticker_id;
        std::string unicode;

        public:
        const std::string & get_category_id() const;
        std::string & get_mut_category_id();
        void set_category_id(const std::string & value) ;

        const std::string & get_category_name() const;
        std::string & get_mut_category_name();
        void set_category_name(const std::string & value) ;

        const std::string & get_icon_url() const;
        std::string & get_mut_icon_url();
        void set_icon_url(const std::string & value) ;

        const std::string & get_name() const;
        std::string & get_mut_name();
        void set_name(const std::string & value) ;

        const std::string & get_path() const;
        std::string & get_mut_path();
        void set_path(const std::string & value) ;

        const std::string & get_preview_cover_url() const;
        std::string & get_mut_preview_cover_url();
        void set_preview_cover_url(const std::string & value) ;

        const std::string & get_resource_id() const;
        std::string & get_mut_resource_id();
        void set_resource_id(const std::string & value) ;

        const int64_t & get_source_platform() const;
        int64_t & get_mut_source_platform();
        void set_source_platform(const int64_t & value) ;

        const std::string & get_sticker_id() const;
        std::string & get_mut_sticker_id();
        void set_sticker_id(const std::string & value) ;

        const std::string & get_unicode() const;
        std::string & get_mut_unicode();
        void set_unicode(const std::string & value) ;
    };
}
