//
//  ACCPropRecommendMusicProtocol.h
//  CameraClient
//
//  Created by xiaojuan on 2020/8/9.
//
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ACCAVPlayerPlayStatus) {
    ACCAVPlayerPlayStatusInitial, // 0
    ACCAVPlayerPlayStatusLoading, // 1
    ACCAVPlayerPlayStatusPlaying, // 2
    ACCAVPlayerPlayStatusPause, // 3
    ACCAVPlayerPlayStatusReachEnd, // 4
    ACCAVPlayerPlayStatusFail, // 5
};

@protocol ACCPropRecommendMusicProtocol <NSObject>

- (void)configDelegateViewWithStatus:(ACCAVPlayerPlayStatus)status;

@end
