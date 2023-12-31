//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class TutorialInfo;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class TrackInfo {
        public:
        TrackInfo();
        virtual ~TrackInfo();

        private:
        std::string template_id;
        std::vector<std::string> transfer_paths;
        std::shared_ptr<TutorialInfo> tutorial_info;

        public:
        const std::string & get_template_id() const;
        std::string & get_mut_template_id();
        void set_template_id(const std::string & value) ;

        const std::vector<std::string> & get_transfer_paths() const;
        std::vector<std::string> & get_mut_transfer_paths();
        void set_transfer_paths(const std::vector<std::string> & value) ;

        const std::shared_ptr<TutorialInfo> & get_tutorial_info() const;
        std::shared_ptr<TutorialInfo> & get_mut_tutorial_info();
        void set_tutorial_info(const std::shared_ptr<TutorialInfo> & value) ;
    };
}
