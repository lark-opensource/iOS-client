//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Keyframe.h"
namespace CutSame {
    class MaskConfig;
    class Point;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class VideoKeyframe : public Keyframe {
        public:
        VideoKeyframe();
        virtual ~VideoKeyframe();

        private:
        double alpha;
        double brightness_value;
        double chroma_intensity;
        double chroma_shadow;
        double contrast_value;
        double fade_value;
        double filter_value;
        double highlight_value;
        double last_volume;
        double light_sensation_value;
        std::shared_ptr<MaskConfig> mask_config;
        double particle_value;
        std::shared_ptr<Point> position;
        double rotation;
        double saturation_value;
        std::shared_ptr<Point> scale;
        double shadow_value;
        double sharpen_value;
        double temperature_value;
        double tone_value;
        double vignetting_value;
        double volume;

        public:
        const double & get_alpha() const;
        double & get_mut_alpha();
        void set_alpha(const double & value) ;

        const double & get_brightness_value() const;
        double & get_mut_brightness_value();
        void set_brightness_value(const double & value) ;

        const double & get_chroma_intensity() const;
        double & get_mut_chroma_intensity();
        void set_chroma_intensity(const double & value) ;

        const double & get_chroma_shadow() const;
        double & get_mut_chroma_shadow();
        void set_chroma_shadow(const double & value) ;

        const double & get_contrast_value() const;
        double & get_mut_contrast_value();
        void set_contrast_value(const double & value) ;

        const double & get_fade_value() const;
        double & get_mut_fade_value();
        void set_fade_value(const double & value) ;

        const double & get_filter_value() const;
        double & get_mut_filter_value();
        void set_filter_value(const double & value) ;

        const double & get_highlight_value() const;
        double & get_mut_highlight_value();
        void set_highlight_value(const double & value) ;

        const double & get_last_volume() const;
        double & get_mut_last_volume();
        void set_last_volume(const double & value) ;

        const double & get_light_sensation_value() const;
        double & get_mut_light_sensation_value();
        void set_light_sensation_value(const double & value) ;

        const std::shared_ptr<MaskConfig> & get_mask_config() const;
        std::shared_ptr<MaskConfig> & get_mut_mask_config();
        void set_mask_config(const std::shared_ptr<MaskConfig> & value) ;

        const double & get_particle_value() const;
        double & get_mut_particle_value();
        void set_particle_value(const double & value) ;

        const std::shared_ptr<Point> & get_position() const;
        std::shared_ptr<Point> & get_mut_position();
        void set_position(const std::shared_ptr<Point> & value) ;

        const double & get_rotation() const;
        double & get_mut_rotation();
        void set_rotation(const double & value) ;

        const double & get_saturation_value() const;
        double & get_mut_saturation_value();
        void set_saturation_value(const double & value) ;

        const std::shared_ptr<Point> & get_scale() const;
        std::shared_ptr<Point> & get_mut_scale();
        void set_scale(const std::shared_ptr<Point> & value) ;

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

        const double & get_volume() const;
        double & get_mut_volume();
        void set_volume(const double & value) ;
    };
}
