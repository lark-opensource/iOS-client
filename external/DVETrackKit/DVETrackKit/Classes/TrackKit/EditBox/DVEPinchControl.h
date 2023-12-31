//
//  DVEPinchControl.h
//  TTVideoEditorDemo
//
//  created by bytedance on 2020/12/8.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEPinchControl : UIControl

- (instancetype)initWithReferView:(UIView *)view;

- (void)setDefaultImage:(UIImage *)defaultImg highlightImage:(UIImage *)highlightImage;

// Relative to begin touch point.
@property (nonatomic) CGFloat scale;
// Relative to last changed touch point.
@property (nonatomic) CGFloat rotationInterval;

@end

NS_ASSUME_NONNULL_END
