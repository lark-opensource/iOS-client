//
// Created by liuyang.10 on 2018/11/28.
//

#ifndef EFFECT_SDK_BEF_EFFECTED_AVATAR_DRIVE_DEFINE_H
#define EFFECT_SDK_BEF_EFFECTED_AVATAR_DRIVE_DEFINE_H

#include "bef_framework_public_geometry_define.h"

#define BEF_AM_E_DIM 52
#define BEF_AM_U_DIM 75

typedef struct  bef_avtar_drive_info_st {
    float alpha[BEF_AM_U_DIM];
    float beta[BEF_AM_E_DIM];
    float landmarks[240*2];
    float rot[3];
    float mvp[16];
    float mv[16];
    float affine_mat[9];
    int succ;
    int ID;
    unsigned int action;          // action, refer to bef_effect_face_detect.h
} bef_avatar_drive_info;
#endif //EFFECT_SDK_BEF_EFFECTED_AVATAR_DRIVE_DEFINE_H
