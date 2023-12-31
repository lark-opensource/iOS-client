//
//  ACCDuetLayoutComponent.h
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/2/14.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCFeatureComponent.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCameraService, ACCRecorderViewContainer;

@interface ACCDuetLayoutComponent : ACCFeatureComponent

@property (nonatomic, strong, readonly) id<ACCCameraService> cameraService;
@property (nonatomic, strong, readonly) id<ACCRecorderViewContainer> viewContainer;

@end

NS_ASSUME_NONNULL_END
