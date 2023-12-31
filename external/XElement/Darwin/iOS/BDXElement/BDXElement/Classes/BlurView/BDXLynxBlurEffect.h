//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxBlurEffect : UIBlurEffect

+ (UIBlurEffect* _Nullable)effectWithStyle:(UIBlurEffectStyle)style
                                blurRadius:(CGFloat)radius;

@end

NS_ASSUME_NONNULL_END
