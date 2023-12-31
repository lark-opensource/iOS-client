//
//  UIView+ACCStickerSDKMasonry.h
//  CameraClient-Pods-Aweme
//
//  Created by xiubin on 2020/8/25.
//

#import <UIKit/UIKit.h>

#define ACCSMasMaker(view, constraints) {\
    MASConstraintMaker *make = [view accs_makeConstraint];\
    if (make) {\
        constraints\
        [make install];\
    }\
}

#define ACCSMasUpdate(view, constraints) {\
    MASConstraintMaker *make = [view accs_updateConstraint];\
    if (make) {\
        constraints\
        [make install];\
    }\
}

#define ACCSMasReMaker(view, constraints) {\
    MASConstraintMaker *make = [view accs_remakeConstraint];\
    if (make) {\
        constraints\
        [make install];\
    }\
}

NS_ASSUME_NONNULL_BEGIN

@class MASConstraintMaker;

@interface UIView (ACCStickerSDKMasonry)

- (MASConstraintMaker *)accs_makeConstraint;

- (MASConstraintMaker *)accs_updateConstraint;

- (MASConstraintMaker *)accs_remakeConstraint;

@end

NS_ASSUME_NONNULL_END
