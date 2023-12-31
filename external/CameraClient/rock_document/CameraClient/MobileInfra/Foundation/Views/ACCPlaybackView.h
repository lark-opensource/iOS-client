//
//  AWEPlaybackView.h
//  AWEStudio
//
//  Created by 旭旭 on 2018/6/5.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVPlayer;

@interface ACCPlaybackView : UIView

@property (weak, nonatomic) AVPlayer *player;

@end
