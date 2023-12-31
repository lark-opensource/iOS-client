//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialAudioFade : public Material {
        public:
        MaterialAudioFade();
        virtual ~MaterialAudioFade();

        private:
        int64_t fade_in_duration;
        int64_t fade_out_duration;

        public:
        const int64_t & get_fade_in_duration() const;
        int64_t & get_mut_fade_in_duration();
        void set_fade_in_duration(const int64_t & value) ;

        const int64_t & get_fade_out_duration() const;
        int64_t & get_mut_fade_out_duration();
        void set_fade_out_duration(const int64_t & value) ;
    };
}
