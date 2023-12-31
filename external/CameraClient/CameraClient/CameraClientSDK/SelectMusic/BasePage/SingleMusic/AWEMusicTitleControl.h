//
//  AWEMusicTitleControl.h
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/19.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AWEMusicTitleControl : UIControl

@property (nonatomic, strong, readonly) UILabel *aweTitleLabel;
@property (nonatomic, strong, readonly) UIView *backgroundColorView;
@property (nonatomic, assign) UIEdgeInsets paddings;

@end
