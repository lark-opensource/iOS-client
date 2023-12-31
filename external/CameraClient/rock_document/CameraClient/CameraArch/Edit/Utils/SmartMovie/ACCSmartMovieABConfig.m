//
//  ACCSmartMovieABConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/7/29.
//

#import "ACCSmartMovieABConfig.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitInfra/ACCConfigManager.h>

@implementation ACCSmartMovieABConfig

+ (BOOL)isOn
{
    return ACCConfigBool(kConfigBool_studio_edit_use_nle) &&
    (ACCConfigInt(kConfigInt_smart_movie_algorithm) != 0);
}

+ (BOOL)defaultSmartMovie
{
    return ACCConfigBool(kConfigBool_studio_edit_use_nle) && ACCConfigInt(kConfigInt_smart_movie_algorithm) == 1;
}

+ (BOOL)defaultMV
{
    return ACCConfigBool(kConfigBool_studio_edit_use_nle) && ACCConfigInt(kConfigInt_smart_movie_algorithm) == 2;
}

@end
