//
// Created by wangchengyi on 2019-11-17.
//

#ifndef CUTSAMEAPP_LVVECanvasFilterParam_H
#define CUTSAMEAPP_LVVECanvasFilterParam_H

#include <string>
using std::string;

namespace cut {
    struct LVVECanvasFilterParam {

        /**
         * 画布背景类型
         */
        string type;

        /**
         * 颜色值
         *
         */
        string color;

        /**
         * 模糊程度 1-14档
         * 0为不模糊
         */
        float blur;

        /**
         * 图片路径
         */
        string imagePath;

        /**
         * 画布宽度
         */
        string ratio;
        int width;
        int height;
    };
}


#endif //CUTSAMEAPP_LVVECanvasFilterParam_H
