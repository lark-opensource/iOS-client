//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class TutorialInfo {
        public:
        TutorialInfo();
        virtual ~TutorialInfo();

        private:
        std::string edit_method;

        public:
        const std::string & get_edit_method() const;
        std::string & get_mut_edit_method();
        void set_edit_method(const std::string & value) ;
    };
}
