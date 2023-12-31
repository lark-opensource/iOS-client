//
//  AWEAudioWaveformView.h
//  Aweme
//
//  Created by 旭旭 on 2017/11/8.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface AWEAudioWaveformView : UIView

@property (nonatomic, assign) CGFloat hasRecordedLocation;
@property (nonatomic, assign) CGFloat playingLocation;
@property (nonatomic, assign) CGFloat toBePlayedLocation;

@end
