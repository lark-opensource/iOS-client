//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialAudio : public Material {
        public:
        MaterialAudio();
        virtual ~MaterialAudio();

        private:
        std::string category_id;
        std::string category_name;
        int64_t duration;
        std::string effect_id;
        std::string intensifies_path;
        std::string music_id;
        std::string name;
        std::string path;
        int64_t source_platform;
        std::string text_id;
        std::string tone_type;

        public:
        const std::string & get_category_id() const;
        std::string & get_mut_category_id();
        void set_category_id(const std::string & value) ;

        const std::string & get_category_name() const;
        std::string & get_mut_category_name();
        void set_category_name(const std::string & value) ;

        const int64_t & get_duration() const;
        int64_t & get_mut_duration();
        void set_duration(const int64_t & value) ;

        const std::string & get_effect_id() const;
        std::string & get_mut_effect_id();
        void set_effect_id(const std::string & value) ;

        const std::string & get_intensifies_path() const;
        std::string & get_mut_intensifies_path();
        void set_intensifies_path(const std::string & value) ;

        const std::string & get_music_id() const;
        std::string & get_mut_music_id();
        void set_music_id(const std::string & value) ;

        const std::string & get_name() const;
        std::string & get_mut_name();
        void set_name(const std::string & value) ;

        const std::string & get_path() const;
        std::string & get_mut_path();
        void set_path(const std::string & value) ;

        const int64_t & get_source_platform() const;
        int64_t & get_mut_source_platform();
        void set_source_platform(const int64_t & value) ;

        const std::string & get_text_id() const;
        std::string & get_mut_text_id();
        void set_text_id(const std::string & value) ;

        const std::string & get_tone_type() const;
        std::string & get_mut_tone_type();
        void set_tone_type(const std::string & value) ;
    };
}
