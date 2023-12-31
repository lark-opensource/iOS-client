//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Keyframe.h"

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class AdjustKeyframe : public Keyframe {
        public:
        AdjustKeyframe();
        virtual ~AdjustKeyframe();

        private:
        double brightness_value;
        double contrast_value;
        double fade_value;
        double highlight_value;
        double light_sensation_value;
        double particle_value;
        double saturation_value;
        double shadow_value;
        double sharpen_value;
        double temperature_value;
        double tone_value;
        double vignetting_value;

        public:
        const double & get_brightness_value() const;
        double & get_mut_brightness_value();
        void set_brightness_value(const double & value) ;

        const double & get_contrast_value() const;
        double & get_mut_contrast_value();
        void set_contrast_value(const double & value) ;

        const double & get_fade_value() const;
        double & get_mut_fade_value();
        void set_fade_value(const double & value) ;

        const double & get_highlight_value() const;
        double & get_mut_highlight_value();
        void set_highlight_value(const double & value) ;

        const double & get_light_sensation_value() const;
        double & get_mut_light_sensation_value();
        void set_light_sensation_value(const double & value) ;

        const double & get_particle_value() const;
        double & get_mut_particle_value();
        void set_particle_value(const double & value) ;

        const double & get_saturation_value() const;
        double & get_mut_saturation_value();
        void set_saturation_value(const double & value) ;

        const double & get_shadow_value() const;
        double & get_mut_shadow_value();
        void set_shadow_value(const double & value) ;

        const double & get_sharpen_value() const;
        double & get_mut_sharpen_value();
        void set_sharpen_value(const double & value) ;

        const double & get_temperature_value() const;
        double & get_mut_temperature_value();
        void set_temperature_value(const double & value) ;

        const double & get_tone_value() const;
        double & get_mut_tone_value();
        void set_tone_value(const double & value) ;

        const double & get_vignetting_value() const;
        double & get_mut_vignetting_value();
        void set_vignetting_value(const double & value) ;
    };
}
