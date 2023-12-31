//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"
namespace CutSame {
    class MaskConfig;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialMask : public Material {
        public:
        MaterialMask();
        virtual ~MaterialMask();

        private:
        std::shared_ptr<MaskConfig> config;
        std::string name;
        std::string path;
        std::string resource_id;
        std::string resource_type;

        public:
        const std::shared_ptr<MaskConfig> & get_config() const;
        std::shared_ptr<MaskConfig> & get_mut_config();
        void set_config(const std::shared_ptr<MaskConfig> & value) ;

        const std::string & get_name() const;
        std::string & get_mut_name();
        void set_name(const std::string & value) ;

        const std::string & get_path() const;
        std::string & get_mut_path();
        void set_path(const std::string & value) ;

        const std::string & get_resource_id() const;
        std::string & get_mut_resource_id();
        void set_resource_id(const std::string & value) ;

        const std::string & get_resource_type() const;
        std::string & get_mut_resource_type();
        void set_resource_type(const std::string & value) ;
    };
}
