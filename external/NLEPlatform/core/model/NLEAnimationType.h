//
//  NLEAnimationType.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/6/3.
//

#ifndef NLEPLATFORM_MODEL_NLEANIMATIONTYPE_h
#define NLEPLATFORM_MODEL_NLEANIMATIONTYPE_h
#include "nle_export.h"

namespace cut::model {
/**
 多视频导入或者照片电影导入，添加的转场类型
 */
    enum NLE_EXPORT_CLASS class NLEMediaTransType : int {
        NONE = 0,   // 无动画
        PATH = 1,   // 下发的effect 效果
        ZOOM = 2,   // 图片放大缩小
    };
}


#endif /* NLEPLATFORM_MODEL_NLEANIMATIONTYPE */
