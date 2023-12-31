//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class TrackInfo;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class ExtraInfo {
        public:
        ExtraInfo();
        virtual ~ExtraInfo();

        private:
        std::shared_ptr<TrackInfo> track_info;

        public:
        const std::shared_ptr<TrackInfo> & get_track_info() const;
        std::shared_ptr<TrackInfo> & get_mut_track_info();
        void set_track_info(const std::shared_ptr<TrackInfo> & value) ;
    };
}
