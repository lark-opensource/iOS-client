//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class VeConfig {
        public:
        VeConfig();
        virtual ~VeConfig();

        private:
        bool auto_prepare;
        bool ve_ctrl_surface;

        public:
        const bool & get_auto_prepare() const;
        bool & get_mut_auto_prepare();
        void set_auto_prepare(const bool & value) ;

        const bool & get_ve_ctrl_surface() const;
        bool & get_mut_ve_ctrl_surface();
        void set_ve_ctrl_surface(const bool & value) ;
    };
}
