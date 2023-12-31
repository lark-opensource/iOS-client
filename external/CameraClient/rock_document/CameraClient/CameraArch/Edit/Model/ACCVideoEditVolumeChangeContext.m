//
//  ACCVideoEditVolumeChangeContext.m
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/1/7.
//

#import "ACCVideoEditVolumeChangeContext.h"

@implementation ACCVideoEditVolumeChangeContext

+ (instancetype)createWithPanelView:(HTSVideoSoundEffectPanelView *)panelView changeType:(ACCVideoEditVolumeChangeType)changeType
{
    ACCVideoEditVolumeChangeContext *context = [ACCVideoEditVolumeChangeContext new];
    context.panelView = panelView;
    context.changeType = changeType;
    return context;
}

@end
