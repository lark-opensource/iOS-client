//
//  ACCMeteorModeUtils.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMeteorModeUtils : NSObject

+ (BOOL)supportMeteorMode;

+ (BOOL)hasUsedMeteorMode;

+ (void)markHasUseMeteorMode;

+ (BOOL)needShowMeteorModeBubbleGuide;

+ (void)markHasShowenMeteorModeBubbleGuide;

@end

NS_ASSUME_NONNULL_END
