//
// Created by wangchengyi on 2019-11-18.
//

#ifndef CUTSAMEAPP_VIDEODATA_H
#define CUTSAMEAPP_VIDEODATA_H

#include <string>
#include <vector>
#include <TemplateConsumer/model.hpp>
#include <cut/param/filter/LVVECanvasFilterParam.h>

namespace cut {
    using namespace std;

    struct VideoData {

    public:
        // 视频所属segment id
        vector<string> videoSegments;
        // 视频段数据
        vector<string> videoPaths;
        // 视频类型，video、photo
        vector<string> videoTypes;
        // 源视频剪辑数据
        vector<CutSame::Timerange> videoSourceTimeClipInfo;

        vector<CutSame::Timerange> videoTargetTimeClipInfo;
        // 画布信息
        vector<LVVECanvasFilterParam> canvasParams;
        // 转场信息
        vector<CutSame::MaterialTransition> transitionParams;
        // 视频速率信息
        vector<float> speed;

        VideoData() {}

    };

}
#endif //CUTSAMEAPP_VIDEODATA_H
