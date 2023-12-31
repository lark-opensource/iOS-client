//
//  ACCCameraWrapper.h
//  Pods
//
//  Created by liyingpeng on 2020/5/28.
//

#ifndef ACCCameraWrapper_h
#define ACCCameraWrapper_h

@protocol VERecorderPublicProtocol, ACCCameraProvider;

@protocol ACCCameraWrapper <NSObject>

// only for story
- (void)setCamera:(id<VERecorderPublicProtocol>)camera;

- (void)setCameraProvider:(id<ACCCameraProvider>)cameraProvider;

@end

#endif /* ACCCameraWrapper_h */
