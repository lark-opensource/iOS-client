//
//  ACCCameraService.h
//  Pods
//
//  Created by liyingpeng on 2020/5/28.
//

#ifndef ACCCameraService_h
#define ACCCameraService_h

#import "ACCCameraControlProtocol.h"
#import "ACCFilterProtocol.h"
#import "ACCEffectProtocol.h"
#import "ACCBeautyProtocol.h"
#import "ACCRecorderProtocol.h"
#import "ACCAlgorithmProtocol.h"
#import "ACCMessageProtocol.h"
#import "ACCKaraokeProtocol.h"

#import "ACCCameraLifeCircleEvent.h"
#import "ACCCameraSubscription.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCameraFactory;
@class AWECameraPreviewContainerView;

typedef void(^ACCCameraCompletionBlock)(void);

@protocol ACCCameraCapabilities <NSObject>

@property (nonatomic, strong, readonly) id<ACCCameraControlProtocol> cameraControl;
@property (nonatomic, strong, readonly) id<ACCFilterProtocol> filter;
@property (nonatomic, strong, readonly) id<ACCEffectProtocol> effect;
@property (nonatomic, strong, readonly) id<ACCBeautyProtocol> beauty;
@property (nonatomic, strong, readonly) id<ACCRecorderProtocol> recorder;
@property (nonatomic, strong, readonly) id<ACCAlgorithmProtocol> algorithm;
@property (nonatomic, strong, readonly) id<ACCMessageProtocol> message;
@property (nonatomic, strong, readonly) id<ACCKaraokeProtocol> karaoke;

@end

@protocol ACCCameraService <ACCCameraSubscription, ACCCameraCapabilities>

@property (nonatomic, assign, readonly) BOOL cameraHasInit; // camera confit complete
@property (nonatomic, strong, readonly) AWECameraPreviewContainerView *cameraPreviewView;

@property (nonatomic, strong) id<ACCCameraFactory> cameraFactory;
@property (nonatomic, strong) IESMMCameraConfig *config;

- (void)buildCameraIfNeeded;
- (void)updatePreviewViewOrientation;
- (void)markComponentsLoadFinished;

- (id)resolveObject:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCCameraService_h */
