//
// Created by bytedance on 2021/5/26.
//

#ifndef TEMPLATECONSUMERAPP_SCENETYPE_H
#define TEMPLATECONSUMERAPP_SCENETYPE_H


namespace script::model {

    enum class SceneType : int {
        SCENE_COMMON = 1,
        SCENE_STUCK = 2,
    };

    enum class DownLoadType : int{
        NONE = 0,
        EFFECT = 1,
        MUSIC = 2,
        VIDEO = 3,
        FILE = 4,
        TRANSITION = 5,
        STICKERTEXT = 6
    };

    enum class CanvasRatioType  : int {
        RATIO_16_9 = 1,
        RATIO_1_1 = 2,
        RATIO_3_4 = 3,
        RATIO_4_3 = 4,
        RATIO_9_16 = 5
    };

}


#endif //TEMPLATECONSUMERAPP_SCENETYPE_H
