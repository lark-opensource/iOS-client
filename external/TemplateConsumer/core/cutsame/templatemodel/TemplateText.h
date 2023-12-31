//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class TemplateText {
        public:
        TemplateText();
        virtual ~TemplateText();

        private:
        std::vector<double> bounding_box;
        double duration;
        int64_t index;
        double start_time;
        std::string value;

        public:
        const std::vector<double> & get_bounding_box() const;
        std::vector<double> & get_mut_bounding_box();
        void set_bounding_box(const std::vector<double> & value) ;

        const double & get_duration() const;
        double & get_mut_duration();
        void set_duration(const double & value) ;

        const int64_t & get_index() const;
        int64_t & get_mut_index();
        void set_index(const int64_t & value) ;

        const double & get_start_time() const;
        double & get_mut_start_time();
        void set_start_time(const double & value) ;

        const std::string & get_value() const;
        std::string & get_mut_value();
        void set_value(const std::string & value) ;
    };
}
