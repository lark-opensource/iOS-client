//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class EffectTemplate : public Material {
        public:
        EffectTemplate();
        virtual ~EffectTemplate();

        private:
        std::string category_id;
        std::string category_name;
        std::string effect_id;
        std::string name;
        std::string path;
        std::string resource_id;

        public:
        const std::string & get_category_id() const;
        std::string & get_mut_category_id();
        void set_category_id(const std::string & value) ;

        const std::string & get_category_name() const;
        std::string & get_mut_category_name();
        void set_category_name(const std::string & value) ;

        const std::string & get_effect_id() const;
        std::string & get_mut_effect_id();
        void set_effect_id(const std::string & value) ;

        const std::string & get_name() const;
        std::string & get_mut_name();
        void set_name(const std::string & value) ;

        const std::string & get_path() const;
        std::string & get_mut_path();
        void set_path(const std::string & value) ;

        const std::string & get_resource_id() const;
        std::string & get_mut_resource_id();
        void set_resource_id(const std::string & value) ;
    };
}
