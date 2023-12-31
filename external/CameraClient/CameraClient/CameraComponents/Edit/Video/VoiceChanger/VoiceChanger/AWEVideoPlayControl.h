//
//  AWEVideoPlayControl.h
//  Aweme
//
//  Created by Liu Bing on 4/11/17.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AWEVideoPlayControl : UIView

@property (nonatomic, strong) UIImageView *animationView;
@property (nonatomic, assign) BOOL selected;

- (void)setImage:(UIImage *)image;
- (void)setImageWithName:(NSString *)imageName;
- (BOOL)canMove;

@end

@interface AWEVideoProgressControl : AWEVideoPlayControl
- (void)refreshUI;
@end

@interface AWETimeSelectControl : AWEVideoPlayControl

@property (nonatomic, strong) UIColor *shadowColor;

@end
