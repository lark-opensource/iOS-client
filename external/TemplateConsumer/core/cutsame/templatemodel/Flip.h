//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Flip {
        public:
        Flip();
        virtual ~Flip();

        private:
        bool horizontal;
        bool vertical;

        public:
        const bool & get_horizontal() const;
        bool & get_mut_horizontal();
        void set_horizontal(const bool & value) ;

        const bool & get_vertical() const;
        bool & get_mut_vertical();
        void set_vertical(const bool & value) ;
    };
}
