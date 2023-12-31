//
// Created by wangchengyi on 2019/12/18.
// Copyright (c) 2019 zhangyeqi. All rights reserved.
//

#ifndef CUT_IOS_INFOSTICKERBORDERINFO_H
#define CUT_IOS_INFOSTICKERBORDERINFO_H

namespace cut {
    struct InfoStickerBorderInfo {
        // 中心点x
        float x = 0; // -1~1
        // 中心点y
        float y = 0; // -1~1
        float width = 0; // TODO 这里到底是0~2还是0~1还是-1~1，由于中心点是-1~1，所以这里按0~2算
        float height = 0; // TODO 这里到底是0~2还是0~1还是-1~1，由于中心点是-1~1，所以这里按0~2算
        // 旋转角度
        float angle = 0;
    };
}



#endif //CUT_IOS_INFOSTICKERBORDERINFO_H
