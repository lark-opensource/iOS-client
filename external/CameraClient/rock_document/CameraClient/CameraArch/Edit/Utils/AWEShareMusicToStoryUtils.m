//
//  AWEShareMusicToStoryUtils.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/11/25.
//

#import "AWEShareMusicToStoryUtils.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

@implementation AWEShareMusicToStoryUtils

+ (BOOL)enableShareMusicToStoryClipEntry:(ACCVideoCanvasType)canvasType
{
    return (ACCConfigBool(kConfigBool_enable_new_clips) &&
            ACCConfigBool(kConfigBool_enable_share_to_story_add_clip_capacity_in_edit_page) &&
            !ACCConfigBool(kConfigBool_studio_edit_use_nle) &&
            canvasType == ACCVideoCanvasTypeMusicStory);
}

@end
