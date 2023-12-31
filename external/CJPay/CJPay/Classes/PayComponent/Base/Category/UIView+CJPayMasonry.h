//
//  UIView+CJPayMasonry.h
//  Pods
//
//  Created by xiuyuanLee on 2021/2/25.
//

#import <UIKit/UIKit.h>

#define CJPayMasMaker(view, constraints) {\
    MASConstraintMaker *make = [view cj_makeConstraint];\
    if (make) {\
        constraints\
        [make install];\
    }\
}

#define CJPayMasUpdate(view, constraints) {\
    MASConstraintMaker *make = [view cj_updateConstraint];\
    if (make) {\
        constraints\
        [make install];\
    }\
}

#define CJPayMasReMaker(view, constraints) {\
    MASConstraintMaker *make = [view cj_remakeConstraint];\
    if (make) {\
        constraints\
        [make install];\
    }\
}

#define CJPayMasArrayMaker(array, constraints) {\
    for (UIView *view in array) {\
        CJPayLogAssert([view isKindOfClass:[UIView class]], @"All objects in the array must be views.");\
        CJPayMasMaker(view, constraints);\
    }\
}\

#define CJPayMasArrayUpdate(array, constraints) {\
    for (UIView *view in array) {\
        CJPayLogAssert([view isKindOfClass:[UIView class]], @"All objects in the array must be views.");\
        CJPayMasUpdate(view, constraints);\
    }\
}\

#define CJPayMasArrayReMaker(array, constraints) {\
    for (UIView *view in array) {\
        CJPayLogAssert([view isKindOfClass:[UIView class]], @"All objects in the array must be views.");\
        CJPayMasReMaker(view, constraints);\
    }\
}\

NS_ASSUME_NONNULL_BEGIN

@class MASConstraintMaker;
@interface UIView (CJPayMasonry)

- (MASConstraintMaker *)cj_makeConstraint;

- (MASConstraintMaker *)cj_updateConstraint;

- (MASConstraintMaker *)cj_remakeConstraint;

@end

NS_ASSUME_NONNULL_END
