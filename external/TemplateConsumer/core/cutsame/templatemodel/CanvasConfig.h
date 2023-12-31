//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class CanvasConfig {
        public:
        CanvasConfig();
        virtual ~CanvasConfig();

        private:
        int64_t height;
        std::string ratio;
        int64_t width;

        public:
        const int64_t & get_height() const;
        int64_t & get_mut_height();
        void set_height(const int64_t & value) ;

        const std::string & get_ratio() const;
        std::string & get_mut_ratio();
        void set_ratio(const std::string & value) ;

        const int64_t & get_width() const;
        int64_t & get_mut_width();
        void set_width(const int64_t & value) ;
    };
}
