//
//  AWEAudioClipView.h
//  Aweme
//
//  Created by 郝一鹏 on 2017/5/3.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWEScrollBarChartView.h"
#import <CreativeKit/ACCPanelViewProtocol.h>

FOUNDATION_EXPORT void * const ACCRecordAudioClipContext;

typedef NS_ENUM(NSInteger, AWEAudioClipViewStyle)
{
    AWEAudioClipViewBottomStyle,
    AWEAudioClipViewTopStyle,
};

@interface AWEAudioClipView : UIView <ACCPanelViewProtocol>

- (instancetype)initWithStyle:(AWEAudioClipViewStyle)style;

@property (nonatomic, strong) UIButton *clipMusicDoneBtn;
@property (nonatomic, strong) UIButton *audioStartTimeIndicatorBtn;
@property (nonatomic, strong) AWEScrollBarChartView *audioBarView;

@end
