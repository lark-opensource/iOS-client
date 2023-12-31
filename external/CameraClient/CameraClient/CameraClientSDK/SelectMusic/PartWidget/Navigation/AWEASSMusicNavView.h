//
//  AWEASSMusicNavView.h
//  AWEStudio
//
//  Created by 旭旭 on 2018/8/31.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AWEASSMusicNavView : UIView

@property (nonatomic, assign) BOOL leftButtonIsBack;
@property (nonatomic, strong) UIButton *leftCancelButton;//左上角的X
@property (nonatomic, strong) UILabel *titleLabel;

- (void)updateLayout;
- (BOOL)isShortStyle;
- (CGFloat)recommendHeight;

@end
