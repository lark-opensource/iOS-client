//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class RealtimeDenoises : public Material {
        public:
        RealtimeDenoises();
        virtual ~RealtimeDenoises();

        private:
        double denoise_mode;
        double denoise_rate;
        std::string id;
        bool is_denoise;
        std::string path;
        std::string type;

        public:
        const double & get_denoise_mode() const;
        double & get_mut_denoise_mode();
        void set_denoise_mode(const double & value) ;

        const double & get_denoise_rate() const;
        double & get_mut_denoise_rate();
        void set_denoise_rate(const double & value) ;

        const std::string & get_id() const;
        std::string & get_mut_id();
        void set_id(const std::string & value) ;

        const bool & get_is_denoise() const;
        bool & get_mut_is_denoise();
        void set_is_denoise(const bool & value) ;

        const std::string & get_path() const;
        std::string & get_mut_path();
        void set_path(const std::string & value) ;

        const std::string & get_type() const;
        std::string & get_mut_type();
        void set_type(const std::string & value) ;
    };
}
