//
//  ACCMvTemplateSupportOneKeyMvConfig.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/10/9.
//

#import "ACCMvTemplateSupportOneKeyMvConfig.h"

#import <CreationKitInfra/ACCConfigManager.h>
#import <CameraClient/ACCConfigKeyDefines.h>

#define kConfigBool_tools_mv_template_support_one_key_mv \
ACCConfigKeyDefaultPair(@"tools_mv_template_support_one_key_mv", @(NO))

@implementation ACCMvTemplateSupportOneKeyMvConfig

+ (BOOL)enabled
{
    if (ACCConfigInt(kConfigInt_smart_video_entrance) == ACCOneClickFlimingEntranceNone || ACCConfigInt(kConfigInt_smart_video_entrance) == ACCOneClickFlimingEntranceNoButton) {
        return NO;
    }
    return ACCConfigBool(kConfigBool_tools_mv_template_support_one_key_mv);
}

+ (CGFloat)oneKeyBtnOriginY
{
    return 87.f;
}

+ (CGFloat)oneKeyViewHeight
{
    return 80.f;
}

@end
