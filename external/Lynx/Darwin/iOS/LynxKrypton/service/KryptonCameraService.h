//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <CoreMedia/CMSampleBuffer.h>
#import <CoreVideo/CVPixelBuffer.h>
#import "KryptonService.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - KryptonCameraConfig

@interface KryptonCameraConfig : NSObject

/// Camera resolution, optional values: @"low" @"medium" @"high" (refer to realFrameSize for the
/// corresponding actual sample size)
/// Default nil, @medium will be used
@property(nonatomic, copy) NSString *resolution;
/// Camera face mode, optional values: @"back" @"front"
/// Default nil, @"front" will be used
@property(nonatomic, copy) NSString *faceMode;

/// @brief Obtain the real frame size
/// @return real frame size
- (CGSize)realFrameSize;

@end

#pragma mark - KryptonCameraDelegate

@protocol KryptonCameraDelegate <NSObject>
- (void)cameraDidOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

#pragma mark - KryptonCamera

@protocol KryptonCamera <NSObject>

/// @param config  Camera config, instance of KryptonCameraConfig
/// @return Results of requesting camera. errNo: error.code; errMsg: error.localizedDescription;
- (NSError *)requestWithConfig:(KryptonCameraConfig *)config;

/// @param delegate  Camera will hold the delegate until dispose or dealloc
- (void)setDelegate:(id<KryptonCameraDelegate>)delegate;

/// start or resume
- (BOOL)play;

- (BOOL)pause;
- (BOOL)dispose;

- (BOOL)setZoom:(double)zoom;

- (KryptonCameraConfig *)getCameraConfig;

@end

#pragma mark - KryptonCameraService

@protocol KryptonCameraService <KryptonService>

/// Create camera instance
- (id<KryptonCamera>)createCamera;

@end

NS_ASSUME_NONNULL_END
