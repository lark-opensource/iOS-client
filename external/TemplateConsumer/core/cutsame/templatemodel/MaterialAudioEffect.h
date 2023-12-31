//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialAudioEffect : public Material {
        public:
        MaterialAudioEffect();
        virtual ~MaterialAudioEffect();

        private:
        std::string name;

        public:
        const std::string & get_name() const;
        std::string & get_mut_name();
        void set_name(const std::string & value) ;
    };
}
