//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class MutableMaterial;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MutableConfig {
        public:
        MutableConfig();
        virtual ~MutableConfig();

        private:
        std::string align_mode;
        std::vector<std::shared_ptr<MutableMaterial>> mutable_materials;

        public:
        const std::string & get_align_mode() const;
        std::string & get_mut_align_mode();
        void set_align_mode(const std::string & value) ;

        const std::vector<std::shared_ptr<MutableMaterial>> & get_mutable_materials() const;
        std::vector<std::shared_ptr<MutableMaterial>> & get_mut_mutable_materials();
        void set_mutable_materials(const std::vector<std::shared_ptr<MutableMaterial>> & value) ;
    };
}
