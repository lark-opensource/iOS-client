//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"
namespace CutSame {
    class MaterialAnimation;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Animations : public Material {
        public:
        Animations();
        virtual ~Animations();

        private:
        std::vector<std::shared_ptr<MaterialAnimation>> animations;

        public:
        const std::vector<std::shared_ptr<MaterialAnimation>> & get_animations() const;
        std::vector<std::shared_ptr<MaterialAnimation>> & get_mut_animations();
        void set_animations(const std::vector<std::shared_ptr<MaterialAnimation>> & value) ;
    };
}
