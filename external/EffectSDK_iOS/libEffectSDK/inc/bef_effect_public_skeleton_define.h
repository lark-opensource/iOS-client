//
//  bef_effect_public_skeleton_define.h
//  Pods
//
//  Created by bytedance on 2019/6/25.
//

#ifndef EFFECT_SDK_BEF_EFFECT_PUBLIC_SKELETON_DEFINE_H
#define EFFECT_SDK_BEF_EFFECT_PUBLIC_SKELETON_DEFINE_H

#include <string.h>
#include "bef_framework_public_geometry_define.h"

#define BEF_MAX_SKELETON_NUM 5
#define SKELETON_KEY_POINT_NUM 18

typedef struct bef_skeleton_st {
    bef_fpoint_detect point[SKELETON_KEY_POINT_NUM];
    bef_rectf rect;
    int ID;
} bef_skeleton;

typedef struct bef_skeleton_result_st {
    bef_rotate_type orient;
    int body_count;
    bef_skeleton body[BEF_MAX_SKELETON_NUM];
} bef_skeleton_result;
#endif /* bef_effect_public_skeleton_define_h */
