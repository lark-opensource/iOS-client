//
//  UIView+BDPLayout.h
//  Timor
//
//  Created by 傅翔 on 2019/3/8.
//

//#import "BDPMacroUtils.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (BDPLayout)

- (NSArray<NSLayoutConstraint *> *)bdp_constraintEdgesEqualTo:(UIView *)view
                                                   withInsets:(UIEdgeInsets)insets;

@end

NS_ASSUME_NONNULL_END
