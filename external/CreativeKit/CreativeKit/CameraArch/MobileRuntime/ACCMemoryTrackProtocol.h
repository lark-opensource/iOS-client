//
//  ACCMemoryTrackProtocol.h
//  CameraClient
//
// Created by Liu Bing on March 27, 2020
//

#import <Foundation/Foundation.h>
#import "ACCServiceLocator.h"
NS_ASSUME_NONNULL_BEGIN

static NSString * const kAWEStudioSceneCreate = @"create_scene";
static NSString * const kAWEStudioSceneEffect = @"effect_scene";

@protocol ACCMemoryTrackProtocol <NSObject>

- (void)startSceneWithViewController:(UIViewController *)viewController info:(nullable NSDictionary *)info;
- (void)finishSceneWithViewController:(UIViewController *)viewController info:(nullable NSDictionary *)info;

- (void)startScene:(NSString *)scene withKey:(NSString *)key info:(nullable NSDictionary *)info;
- (void)finishScene:(NSString *)scene withKey:(NSString *)key info:(nullable NSDictionary *)info;

- (void)resetMemoryWarningCountWithScene:(NSString *)scene key:(NSString *)key;

- (void)increaseCreateCount;
@end

FOUNDATION_STATIC_INLINE id<ACCMemoryTrackProtocol> ACCMemoryTrack() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCMemoryTrackProtocol)];
}

NS_ASSUME_NONNULL_END
