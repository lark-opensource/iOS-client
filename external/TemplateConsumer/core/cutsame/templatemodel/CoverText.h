//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class Clip;
    class MaterialText;
    class MaterialEffect;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class CoverText {
        public:
        CoverText();
        virtual ~CoverText();

        private:
        std::shared_ptr<Clip> clip;
        std::shared_ptr<MaterialText> text;
        std::shared_ptr<MaterialEffect> text_effect;
        std::shared_ptr<MaterialEffect> text_shape;

        public:
        const std::shared_ptr<Clip> & get_clip() const;
        std::shared_ptr<Clip> & get_mut_clip();
        void set_clip(const std::shared_ptr<Clip> & value) ;

        const std::shared_ptr<MaterialText> & get_text() const;
        std::shared_ptr<MaterialText> & get_mut_text();
        void set_text(const std::shared_ptr<MaterialText> & value) ;

        const std::shared_ptr<MaterialEffect> & get_text_effect() const;
        std::shared_ptr<MaterialEffect> & get_mut_text_effect();
        void set_text_effect(const std::shared_ptr<MaterialEffect> & value) ;

        const std::shared_ptr<MaterialEffect> & get_text_shape() const;
        std::shared_ptr<MaterialEffect> & get_mut_text_shape();
        void set_text_shape(const std::shared_ptr<MaterialEffect> & value) ;
    };
}
