//
//  ACCButton.h
//  ACCme
//
//  Created by willorfang on 16/9/6.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACCButton : UIButton

IBInspectable @property (nonatomic, assign) CGFloat selectedAlpha;
@property (nonatomic, strong) UIImageView *imageContentView;

+ (instancetype)buttonWithSelectedAlpha:(CGFloat)selectedAlpha;
+ (instancetype)imageButtonWithSelectedAlpha:(CGFloat)selectedAlpha;

@end
