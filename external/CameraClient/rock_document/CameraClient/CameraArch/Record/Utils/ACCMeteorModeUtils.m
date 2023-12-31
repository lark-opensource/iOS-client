//
//  ACCMeteorModeUtils.m
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/12.
//

#import "ACCMeteorModeUtils.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCCacheProtocol.h>

static NSString * const ACCMeteorModeUsedKey = @"ACCMeteorModeUsedKey";
static NSString * const ACCMeteorModeBubbleGuideKey = @"ACCMeteorModeBubbleGuideKey";

@implementation ACCMeteorModeUtils

+ (BOOL)supportMeteorMode
{
    return ACCConfigBool(ACCConfigBool_meteor_mode_on);
}

+ (BOOL)hasUsedMeteorMode
{
    return [ACCCache() boolForKey:ACCMeteorModeUsedKey];
}

+ (void)markHasUseMeteorMode
{
    [ACCCache() setBool:YES forKey:ACCMeteorModeUsedKey];
}

+ (BOOL)needShowMeteorModeBubbleGuide
{
    return [self supportMeteorMode] && ![self hasUsedMeteorMode] && ![ACCCache() boolForKey:ACCMeteorModeBubbleGuideKey];
}

+ (void)markHasShowenMeteorModeBubbleGuide
{
    [ACCCache() setBool:YES forKey:ACCMeteorModeBubbleGuideKey];
}

@end
