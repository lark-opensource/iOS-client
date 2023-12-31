//
//  UIView+ACCMasonry.h
//  CameraClient-Pods-Aweme
//
//  Created by xiubin on 2020/8/25.
//

#import <UIKit/UIKit.h>
#import <Masonry/Masonry.h>

#define ACCMasMaker(view, constraints) {\
    MASConstraintMaker *make = [view acc_makeConstraint];\
    if (make) {\
        constraints\
        [make install];\
    }\
}

#define ACCMasUpdate(view, constraints) {\
    MASConstraintMaker *make = [view acc_updateConstraint];\
    if (make) {\
        constraints\
        [make install];\
    }\
}

#define ACCMasReMaker(view, constraints) {\
    MASConstraintMaker *make = [view acc_remakeConstraint];\
    if (make) {\
        constraints\
        [make install];\
    }\
}

NS_ASSUME_NONNULL_BEGIN

@class MASConstraintMaker;

@interface UIView (ACCMasonry)

- (MASConstraintMaker *)acc_makeConstraint;

- (MASConstraintMaker *)acc_updateConstraint;

- (MASConstraintMaker *)acc_remakeConstraint;

@end

NS_ASSUME_NONNULL_END
