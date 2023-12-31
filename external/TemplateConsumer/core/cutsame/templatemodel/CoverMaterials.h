//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class CoverText;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class CoverMaterials {
        public:
        CoverMaterials();
        virtual ~CoverMaterials();

        private:
        std::vector<std::shared_ptr<CoverText>> cover_texts;

        public:
        const std::vector<std::shared_ptr<CoverText>> & get_cover_texts() const;
        std::vector<std::shared_ptr<CoverText>> & get_mut_cover_texts();
        void set_cover_texts(const std::vector<std::shared_ptr<CoverText>> & value) ;
    };
}
