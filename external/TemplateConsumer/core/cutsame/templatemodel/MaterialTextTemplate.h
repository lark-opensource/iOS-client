//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "EffectTemplate.h"
namespace CutSame {
    class MaterialResource;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialTextTemplate : public EffectTemplate {
        public:
        MaterialTextTemplate();
        virtual ~MaterialTextTemplate();

        private:
        std::string fallback_font_path;
        std::vector<std::shared_ptr<MaterialResource>> resources;
        int64_t source_platform;

        public:
        const std::string & get_fallback_font_path() const;
        std::string & get_mut_fallback_font_path();
        void set_fallback_font_path(const std::string & value) ;

        const std::vector<std::shared_ptr<MaterialResource>> & get_resources() const;
        std::vector<std::shared_ptr<MaterialResource>> & get_mut_resources();
        void set_resources(const std::vector<std::shared_ptr<MaterialResource>> & value) ;

        const int64_t & get_source_platform() const;
        int64_t & get_mut_source_platform();
        void set_source_platform(const int64_t & value) ;
    };
}
