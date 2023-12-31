//
//  ACCVideoEditTipsDiaryGuideFrequencyChecker.h
//  CameraClient-Pods-Aweme
//
//  Created by ZZZ on 2021/2/23.
//

#import <Foundation/Foundation.h>
#import "ACCConfigKeyDefines.h"

FOUNDATION_EXTERN NSString *const kAWENormalVideoEditQuickPublishDidTapDateKey;
FOUNDATION_EXTERN NSString *const kAWENormalVideoEditQuickPublishGuideTipShowDateKey;

@interface ACCVideoEditTipsDiaryGuideFrequencyChecker : NSObject

+ (BOOL)shouldShowGuideWithKey:(NSString *)key frequency:(ACCEditDiaryGuideFrequency)frequency;

+ (void)markGuideAsTriggeredWithKey:(NSString *)key;

@end
