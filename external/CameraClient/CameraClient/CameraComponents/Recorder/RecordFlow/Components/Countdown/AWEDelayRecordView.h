//
//  AWEDelayRecordView.h
//  Aweme
//
//  Created by 旭旭 on 2017/11/9.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWEAudioWaveformContainerView.h"
#import "ACCButton.h"
#import <CreativeKit/ACCPanelViewProtocol.h>
#import "ACCCountDownModel.h"

FOUNDATION_EXPORT void * const ACCRecordCountDownContext;

@interface AWEDelayRecordView : UIButton <ACCPanelViewProtocol>

@property (nonatomic, strong) AWEAudioWaveformContainerView *audioWaveformContainerView;
@property (nonatomic, strong) ACCButton *delayRecordButton;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *clearView;

- (instancetype)initWithFrame:(CGRect)frame model:(ACCCountDownModel *)model;

@end
