//
//  bef_effect_xt_define.h
//  effect-sdk
//
//  Created by Doris on 2020/10/28.
//

#ifndef bef_effect_xt_define_h
#define bef_effect_xt_define_h

typedef enum {
    UNINIT = -1,
    STRETCH,
    QUADRESHAPE,
    ELLIPSESHAPE
} ManualReshapeType;

typedef struct ManualReshapeRectDomain_st {
    int leftUpX;
    int leftUpY;
    int rightUpX;
    int rightUpY;
    int leftBottomX;
    int leftBottomY;
    int rightBottomX;
    int rightBottomY;
} ManualReshapeRectDomain;

typedef struct ManualReshapeStretchParam_st {
    int bottomY;
    int upY;
    int stretchWidthDiff;
    int stretchHeightDiff;
    int shrinkWidthDiff;
    int shrinkHeightDiff;
} ManualReshapeStretchParam;

typedef struct ManualPicDomain_st {
    int left;
    int right;
    int bottom;
    int up;
} ManualPicDomainParam;

#endif /* bef_effect_xt_define_h */
