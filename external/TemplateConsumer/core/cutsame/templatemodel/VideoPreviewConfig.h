//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class VideoPreviewConfig {
        public:
        VideoPreviewConfig();
        virtual ~VideoPreviewConfig();

        private:
        bool loop;

        public:
        const bool & get_loop() const;
        bool & get_mut_loop();
        void set_loop(const bool & value) ;
    };
}
