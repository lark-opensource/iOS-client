//
//  AWEVideoVolumeView.h
//  Aweme
//
//  Created by Quan Quan on 16/8/30.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCPanelViewProtocol.h>
#import "HTSVideoSoundEffectPanelView.h"

@class ACCButton;

@interface AWEVideoVolumeView : UIView<ACCPanelViewProtocol>

@property (nonatomic, strong) HTSVideoSoundEffectPanelView *panelView;
@property (nonatomic, strong) ACCButton *buttonDone;

@end
