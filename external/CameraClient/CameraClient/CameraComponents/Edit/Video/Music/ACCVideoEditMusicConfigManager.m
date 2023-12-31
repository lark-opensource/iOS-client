//
//  ACCVideoEditMusicConfigManager.m
//  CameraClient-Pods-Aweme
//
//  Created by LeonZou on 2021/8/2.
//

#import "ACCVideoEditMusicConfigManager.h"
#import "ACCSmartMovieABConfig.h"
#import "ACCSmartMovieManagerProtocol.h"
#import <CreativeKit/ACCServiceLocator.h>

@implementation ACCVideoEditMusicConfigManager

- (BOOL)enableUseMusicFromHost
{
    // 可以由多个业务方配置音乐列表
    
    // 智能照片电影
    if ([ACCSmartMovieABConfig isOn]) {
        id<ACCSmartMovieManagerProtocol> dataProvider = acc_sharedSmartMovieManager();
        // 智照AB开启的情况下，mv和智照都使用智照配乐
        if ([dataProvider isSmartMovieMode] || [dataProvider isMVVideoMode]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSArray<id<ACCMusicModelProtocol>> *)getVideoEditMusicModelArray
{
    // 可以由多个业务方配置音乐列表
    
    // 智能照片电影
    if ([ACCSmartMovieABConfig isOn]) {
        id<ACCSmartMovieManagerProtocol> dataProvider = acc_sharedSmartMovieManager();
        // 智照AB开启的情况下，mv和智照都使用智照配乐
        if ([dataProvider isSmartMovieMode] || [dataProvider isMVVideoMode]) {
            return [dataProvider recommendMusicList];
        }
    }
    return nil;
}

@end
