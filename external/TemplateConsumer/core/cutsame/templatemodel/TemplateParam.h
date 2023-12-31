//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class TemplateText;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class TemplateParam {
        public:
        TemplateParam();
        virtual ~TemplateParam();

        private:
        std::vector<double> bounding_box;
        double duration;
        std::vector<std::string> fallback_font_list;
        int64_t order_in_layer;
        std::vector<double> position;
        double rotation;
        std::vector<double> scale;
        double start_time;
        std::vector<std::shared_ptr<TemplateText>> text_list;

        public:
        const std::vector<double> & get_bounding_box() const;
        std::vector<double> & get_mut_bounding_box();
        void set_bounding_box(const std::vector<double> & value) ;

        const double & get_duration() const;
        double & get_mut_duration();
        void set_duration(const double & value) ;

        const std::vector<std::string> & get_fallback_font_list() const;
        std::vector<std::string> & get_mut_fallback_font_list();
        void set_fallback_font_list(const std::vector<std::string> & value) ;

        const int64_t & get_order_in_layer() const;
        int64_t & get_mut_order_in_layer();
        void set_order_in_layer(const int64_t & value) ;

        const std::vector<double> & get_position() const;
        std::vector<double> & get_mut_position();
        void set_position(const std::vector<double> & value) ;

        const double & get_rotation() const;
        double & get_mut_rotation();
        void set_rotation(const double & value) ;

        const std::vector<double> & get_scale() const;
        std::vector<double> & get_mut_scale();
        void set_scale(const std::vector<double> & value) ;

        const double & get_start_time() const;
        double & get_mut_start_time();
        void set_start_time(const double & value) ;

        const std::vector<std::shared_ptr<TemplateText>> & get_text_list() const;
        std::vector<std::shared_ptr<TemplateText>> & get_mut_text_list();
        void set_text_list(const std::vector<std::shared_ptr<TemplateText>> & value) ;
    };
}
