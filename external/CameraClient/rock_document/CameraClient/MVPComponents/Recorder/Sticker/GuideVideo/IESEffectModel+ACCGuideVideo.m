//
//  IESEffectModel+ACCGuideVideo.m
//  CameraClient-Pods-Aweme
//
//  Created by Howie on 2021/3/7.
//

#import "IESEffectModel+ACCGuideVideo.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

@implementation IESEffectModel (ACCGuideVideo)

- (NSString *)acc_guideVideoPath
{
    NSString *subpath = [self.pixaloopSDKExtra acc_stringValueForKey:@"guide_video_path"];
    if (subpath.length > 0) {
        return [self.filePath stringByAppendingPathComponent:subpath];
    }
    return nil;
}

@end
