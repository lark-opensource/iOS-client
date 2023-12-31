//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"
namespace CutSame {
    class AdjustParamsInfo;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialEffect : public Material {
        public:
        MaterialEffect();
        virtual ~MaterialEffect();

        private:
        std::vector<std::shared_ptr<AdjustParamsInfo>> adjust_params;
        int64_t apply_target_type;
        std::string category_id;
        std::string category_name;
        std::string effect_id;
        std::string name;
        std::string path;
        std::string resource_id;
        int64_t source_platform;
        double value;
        std::string version;

        public:
        const std::vector<std::shared_ptr<AdjustParamsInfo>> & get_adjust_params() const;
        std::vector<std::shared_ptr<AdjustParamsInfo>> & get_mut_adjust_params();
        void set_adjust_params(const std::vector<std::shared_ptr<AdjustParamsInfo>> & value) ;

        const int64_t & get_apply_target_type() const;
        int64_t & get_mut_apply_target_type();
        void set_apply_target_type(const int64_t & value) ;

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

        const int64_t & get_source_platform() const;
        int64_t & get_mut_source_platform();
        void set_source_platform(const int64_t & value) ;

        const double & get_value() const;
        double & get_mut_value();
        void set_value(const double & value) ;

        const std::string & get_version() const;
        std::string & get_mut_version();
        void set_version(const std::string & value) ;
    };
}
