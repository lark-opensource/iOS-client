//
//  ACCCameraFactory.h
//  Pods
//
//  Created by liyingpeng on 2020/7/6.
//

#ifndef ACCCameraFactory_h
#define ACCCameraFactory_h

#import "ACCCameraTypeDefine.h"

typedef void(^ACCCameraFactoryCompletionBlock)(void);

@class IESMMCamera, AWECameraPreviewContainerView;

@protocol ACCCameraBuildListener <NSObject>
- (void)onCameraInit:(ACCCameraType)camera;
@end

@protocol ACCCameraProvider <NSObject>

@property (nonatomic, strong, readonly) AWECameraPreviewContainerView *cameraPreviewView;
@property (nonatomic, strong, readonly) ACCCameraType camera;

- (void)addCameraListener:(id<ACCCameraBuildListener>)listener;

@end

@protocol ACCCameraFactory <ACCCameraProvider>
- (ACCCameraType)buildCameraWithContext:(const void *)context completionBlock:(ACCCameraFactoryCompletionBlock)completionBlock;
@end

#endif /* ACCCameraFactory_h */
