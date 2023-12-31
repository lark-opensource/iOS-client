//
//  LVGeometry.h
//  longVideo
//
//  Created by zenglifeng on 2019/7/18.
//

#ifndef LVGeometry_h
#define LVGeometry_h
struct LVFlip {
    BOOL vertical;
    BOOL horizontal;
};
typedef struct LVFlip LVFlip;

CG_INLINE LVFlip
LVFlipMake(BOOL vertical, BOOL horizontal)
{
    LVFlip flip;
    flip.vertical = vertical;
    flip.horizontal = horizontal;
    return flip;
};

typedef CGPoint LVScale;
typedef CGPoint LVTranslation;


#endif /* LVGeometry_h */
