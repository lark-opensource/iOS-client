//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"
namespace CutSame {
    class Point;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialText : public Material {
        public:
        MaterialText();
        virtual ~MaterialText();

        private:
        int64_t alignment;
        double background_alpha;
        std::string background_color;
        double bold_width;
        std::string border_color;
        double border_width;
        std::string content;
        std::string fallback_font_path;
        std::string font_id;
        std::string font_name;
        std::string font_path;
        std::string font_resource_id;
        double font_size;
        std::string font_title;
        bool has_shadow;
        int64_t italic_degree;
        std::string ktv_color;
        int64_t layer_weight;
        double letter_spacing;
        double line_spacing;
        double shadow_alpha;
        double shadow_angle;
        std::string shadow_color;
        double shadow_distance;
        std::shared_ptr<Point> shadow_point;
        double shadow_smoothing;
        bool shape_clip_x;
        bool shape_clip_y;
        std::string style_name;
        int64_t sub_type;
        double text_alpha;
        std::string text_color;
        std::vector<std::string> text_to_audio_ids;
        int64_t typesetting;
        bool underline;
        double underline_offset;
        double underline_width;
        bool use_effect_default_color;

        public:
        const int64_t & get_alignment() const;
        int64_t & get_mut_alignment();
        void set_alignment(const int64_t & value) ;

        const double & get_background_alpha() const;
        double & get_mut_background_alpha();
        void set_background_alpha(const double & value) ;

        const std::string & get_background_color() const;
        std::string & get_mut_background_color();
        void set_background_color(const std::string & value) ;

        const double & get_bold_width() const;
        double & get_mut_bold_width();
        void set_bold_width(const double & value) ;

        const std::string & get_border_color() const;
        std::string & get_mut_border_color();
        void set_border_color(const std::string & value) ;

        const double & get_border_width() const;
        double & get_mut_border_width();
        void set_border_width(const double & value) ;

        const std::string & get_content() const;
        std::string & get_mut_content();
        void set_content(const std::string & value) ;

        const std::string & get_fallback_font_path() const;
        std::string & get_mut_fallback_font_path();
        void set_fallback_font_path(const std::string & value) ;

        const std::string & get_font_id() const;
        std::string & get_mut_font_id();
        void set_font_id(const std::string & value) ;

        const std::string & get_font_name() const;
        std::string & get_mut_font_name();
        void set_font_name(const std::string & value) ;

        const std::string & get_font_path() const;
        std::string & get_mut_font_path();
        void set_font_path(const std::string & value) ;

        const std::string & get_font_resource_id() const;
        std::string & get_mut_font_resource_id();
        void set_font_resource_id(const std::string & value) ;

        const double & get_font_size() const;
        double & get_mut_font_size();
        void set_font_size(const double & value) ;

        const std::string & get_font_title() const;
        std::string & get_mut_font_title();
        void set_font_title(const std::string & value) ;

        const bool & get_has_shadow() const;
        bool & get_mut_has_shadow();
        void set_has_shadow(const bool & value) ;

        const int64_t & get_italic_degree() const;
        int64_t & get_mut_italic_degree();
        void set_italic_degree(const int64_t & value) ;

        const std::string & get_ktv_color() const;
        std::string & get_mut_ktv_color();
        void set_ktv_color(const std::string & value) ;

        const int64_t & get_layer_weight() const;
        int64_t & get_mut_layer_weight();
        void set_layer_weight(const int64_t & value) ;

        const double & get_letter_spacing() const;
        double & get_mut_letter_spacing();
        void set_letter_spacing(const double & value) ;

        const double & get_line_spacing() const;
        double & get_mut_line_spacing();
        void set_line_spacing(const double & value) ;

        const double & get_shadow_alpha() const;
        double & get_mut_shadow_alpha();
        void set_shadow_alpha(const double & value) ;

        const double & get_shadow_angle() const;
        double & get_mut_shadow_angle();
        void set_shadow_angle(const double & value) ;

        const std::string & get_shadow_color() const;
        std::string & get_mut_shadow_color();
        void set_shadow_color(const std::string & value) ;

        const double & get_shadow_distance() const;
        double & get_mut_shadow_distance();
        void set_shadow_distance(const double & value) ;

        const std::shared_ptr<Point> & get_shadow_point() const;
        std::shared_ptr<Point> & get_mut_shadow_point();
        void set_shadow_point(const std::shared_ptr<Point> & value) ;

        const double & get_shadow_smoothing() const;
        double & get_mut_shadow_smoothing();
        void set_shadow_smoothing(const double & value) ;

        const bool & get_shape_clip_x() const;
        bool & get_mut_shape_clip_x();
        void set_shape_clip_x(const bool & value) ;

        const bool & get_shape_clip_y() const;
        bool & get_mut_shape_clip_y();
        void set_shape_clip_y(const bool & value) ;

        const std::string & get_style_name() const;
        std::string & get_mut_style_name();
        void set_style_name(const std::string & value) ;

        const int64_t & get_sub_type() const;
        int64_t & get_mut_sub_type();
        void set_sub_type(const int64_t & value) ;

        const double & get_text_alpha() const;
        double & get_mut_text_alpha();
        void set_text_alpha(const double & value) ;

        const std::string & get_text_color() const;
        std::string & get_mut_text_color();
        void set_text_color(const std::string & value) ;

        const std::vector<std::string> & get_text_to_audio_ids() const;
        std::vector<std::string> & get_mut_text_to_audio_ids();
        void set_text_to_audio_ids(const std::vector<std::string> & value) ;

        const int64_t & get_typesetting() const;
        int64_t & get_mut_typesetting();
        void set_typesetting(const int64_t & value) ;

        const bool & get_underline() const;
        bool & get_mut_underline();
        void set_underline(const bool & value) ;

        const double & get_underline_offset() const;
        double & get_mut_underline_offset();
        void set_underline_offset(const double & value) ;

        const double & get_underline_width() const;
        double & get_mut_underline_width();
        void set_underline_width(const double & value) ;

        const bool & get_use_effect_default_color() const;
        bool & get_mut_use_effect_default_color();
        void set_use_effect_default_color(const bool & value) ;
    };
}
