//
//  AWEPlaybackView.m
//  AWEStudio
//
//  Created by 旭旭 on 2018/6/5.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCPlaybackView.h"
#import <AVFoundation/AVFoundation.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

@implementation ACCPlaybackView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = ACCResourceColor(ACCColorBGCreation);
        [(AVPlayerLayer *)self.layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    }
    
    return self;
}

- (AVPlayer *)player
{
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end
