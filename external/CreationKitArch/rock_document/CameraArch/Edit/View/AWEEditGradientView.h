//
//  AWEEditGradientView.h
//  AWEStudio
//
//  Created by hanxu on 2018/11/16.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWEStudioExcludeSelfView.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWEEditGradientView : AWEStudioExcludeSelfView

@property (nonatomic, strong, readonly) CAGradientLayer *gradientLayer;

- (instancetype)initWithFrame:(CGRect)frame topColor:(UIColor *)topColor bottomColor:(UIColor *)bottomColor;
- (instancetype)initLeftTop2RightBottomWithColors:(NSArray *)colors;

@end

NS_ASSUME_NONNULL_END
