//
//  ACCCutMusicRangeChangeContext.m
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/1/5.
//

#import "ACCCutMusicRangeChangeContext.h"

@implementation ACCCutMusicRangeChangeContext

+ (instancetype)createWithAudioRange:(HTSAudioRange)range changeType:(AWEAudioClipRangeChangeType)changeType
{
    ACCCutMusicRangeChangeContext *context = [ACCCutMusicRangeChangeContext new];
    context.audioRange = range;
    context.changeType = changeType;
    return context;
}

@end
