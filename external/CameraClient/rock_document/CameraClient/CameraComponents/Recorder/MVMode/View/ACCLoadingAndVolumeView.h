//
//  ACCLoadingAndVolumeView.h
//  Aweme
//
//  Created by hanxu on 2017/2/27.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACCLoadingAndVolumeView : UIView

@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) float progress; //播放进度，[0,1]
@property (nonatomic, assign) BOOL showProgress;

- (void)setVolume:(CGFloat)volume;

@end
