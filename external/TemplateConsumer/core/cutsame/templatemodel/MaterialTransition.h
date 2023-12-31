//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialTransition : public Material {
        public:
        MaterialTransition();
        virtual ~MaterialTransition();

        private:
        std::string category_id;
        std::string category_name;
        int64_t duration;
        std::string effect_id;
        bool is_overlap;
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

        const int64_t & get_duration() const;
        int64_t & get_mut_duration();
        void set_duration(const int64_t & value) ;

        const std::string & get_effect_id() const;
        std::string & get_mut_effect_id();
        void set_effect_id(const std::string & value) ;

        const bool & get_is_overlap() const;
        bool & get_mut_is_overlap();
        void set_is_overlap(const bool & value) ;

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
