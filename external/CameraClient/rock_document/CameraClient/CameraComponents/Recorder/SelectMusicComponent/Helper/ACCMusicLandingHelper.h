//
//  ACCMusicLandingHelper.h
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/4/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMusicLandingHelper : NSObject

+ (BOOL)useMusicShootLandingWithMusicDuration:(CGFloat)musicDuration videoDuration:(CGFloat)videoDuration;

+ (NSInteger)defaultIndexOfCombinedMode:(CGFloat)musicDuration videoDuration:(CGFloat)videoDuration;

+ (CGFloat)recordModeDuration:(CGFloat)musicDuration videoDuration:(CGFloat)videoDuration;

@end

NS_ASSUME_NONNULL_END
