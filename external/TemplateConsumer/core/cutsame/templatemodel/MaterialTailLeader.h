//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "MaterialVideo.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialTailLeader : public MaterialVideo {
        public:
        MaterialTailLeader();
        virtual ~MaterialTailLeader();

        private:
        std::string text;

        public:
        const std::string & get_text() const;
        std::string & get_mut_text();
        void set_text(const std::string & value) ;
    };
}
