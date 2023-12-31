//
//  ACCVideoEditTipsDiaryGuideFrequencyChecker.m
//  CameraClient-Pods-Aweme
//
//  Created by ZZZ on 2021/2/23.
//

#import "ACCVideoEditTipsDiaryGuideFrequencyChecker.h"
#import <CreativeKit/ACCCacheProtocol.h>
#import "ACCConfigKeyDefines.h"

NSString *const kAWENormalVideoEditQuickPublishDidTapDateKey = @"kAWENormalVideoEditQuickPublishDidTapKey";
NSString *const kAWENormalVideoEditQuickPublishGuideTipShowDateKey = @"kAWENormalVideoEditQuickPublishGuideTipShowKey";

@implementation ACCVideoEditTipsDiaryGuideFrequencyChecker

+ (BOOL)shouldShowGuideWithKey:(NSString *)key frequency:(ACCEditDiaryGuideFrequency)frequency
{
    if (!ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
        return NO;
    }

    NSDate *cacheDate = [ACCCache() objectForKey:key];
    const NSInteger secondsOneDay = 24 * 3600;
    CGFloat interval = [[NSDate date] timeIntervalSince1970] - [cacheDate timeIntervalSince1970];

    BOOL ret = NO;
    switch (frequency) {
        case ACCEditDiaryGuideFrequencyNone: {
            break;
        }
        case ACCEditDiaryGuideFrequencyOnce: {
            ret = cacheDate == nil;
            break;
        }
        case ACCEditDiaryGuideFrequencyDaily: {
            ret = interval > secondsOneDay;
            break;
        }
        case ACCEditDiaryGuideFrequencyweekly: {
            ret = interval > secondsOneDay * 7;
            break;
        }
    }
    return ret;
}

+ (void)markGuideAsTriggeredWithKey:(NSString *)key
{
    if (key) {
        [ACCCache() setObject:[NSDate date] forKey:key];
    }
}

@end
