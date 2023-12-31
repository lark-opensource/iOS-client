//
//  ACCRecognitionGrootConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/23.
//

#import "ACCRecognitionGrootConfig.h"
#import "ACCRecognitionConfig.h"
#import <CreationKitInfra/ACCConfigManager.h>
#import <CameraClient/ACCConfigKeyDefines.h>

#define kConfigInt_groot_info_sticker_view_type \
ACCConfigKeyDefaultPair(@"groot_info_sticker_view_type", @(0))

#define kConfigString_studio_groot_stciker_id \
ACCConfigKeyDefaultPair(@"studio_groot_stciker_id", @"1148585")

@implementation ACCRecognitionGrootConfig

+ (BOOL)enabled
{
    return
    [ACCRecognitionConfig supportScene] &&
    [ACCRecognitionConfig supportCategory] &&
    ACCConfigBool(kConfigBool_sticker_support_groot) &&
    self.stickerStyle > 0;
}

+ (NSString *)grootStickerId
{
    return ACCConfigString(kConfigString_studio_groot_stciker_id);
}

+ (NSInteger)stickerStyle
{
    NSInteger style = self.styleAB;
    if (style > 4){
        return 0;
    }
    return style;
}

+ (NSInteger)styleAB
{
    return ACCConfigInt(kConfigInt_groot_info_sticker_view_type);
}
@end
