//
// Created by ZhangYeqiMacPC on 2020-01-07.
//

#ifndef CUT_ANDROID_TEMPLATEINFOLISTENER_H
#define CUT_ANDROID_TEMPLATEINFOLISTENER_H

#include <cstdint>

namespace cut {
    class TemplateInfoListener {
    public:
        /**
         * prepare 进度更新，extra表示进度，范围 [PROGRESS_MIN, PROGRESS_MAX]
         */
        static const int32_t WHAT_PREPARE_PROGRESS = 1000;

        virtual void onInfo(int32_t what, int64_t extra) = 0;
    };
}

#endif //CUT_ANDROID_TEMPLATEINFOLISTENER_H
