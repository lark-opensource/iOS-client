// Copyright 2022 The Lynx Authors. All rights reserved.

#import "KryptonDefaultCamera.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import "KryptonLLog.h"

#include "canvas/gpu/gl/gl_api.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"
#include "third_party/fml/task_runner.h"

@implementation KryptonCameraConfig

- (CGSize)realFrameSize {
  if ([self.resolution isEqualToString:@"low"]) {
    return CGSizeMake(288.f, 352.f);
  } else if ([self.resolution isEqualToString:@"medium"]) {
    return CGSizeMake(480.f, 640.f);
  } else if ([self.resolution isEqualToString:@"high"]) {
    return CGSizeMake(720.f, 1280.f);
  } else {
    return CGSizeMake(480.f, 640.f);
  }
}

@end

@interface KryptonDefaultCamera () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property(strong, nonatomic) KryptonCameraConfig *config;
@property(weak, nonatomic) id<KryptonCameraDelegate> delegate;
@property(assign, nonatomic) GLuint texture;
@property(strong, nonatomic) AVCaptureDevice *device;
@property(strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property(strong, nonatomic) AVCaptureSession *session;
@property(strong, nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property(strong, nonatomic) AVCaptureVideoPreviewLayer *captureLayer;

@end

@implementation KryptonDefaultCameraService
- (id<KryptonCamera>)createCamera {
  return [[KryptonDefaultCamera alloc] init];
}
@end

@implementation KryptonDefaultCamera

- (void)dealloc {
  [_session stopRunning];
}

- (NSError *)requestWithConfig:(KryptonCameraConfig *)config {
  _config = config;
  if (_config == nil) {
    _config = [[KryptonCameraConfig alloc] init];
  }

  static NSString *const errorDomain = @"com.lynx.krypton";
  NSError *error = [self findDevice:errorDomain];
  if (error == nil) {
    error = [self setupCaptureSession:errorDomain];
  }
  return error;
}

- (NSError *)findDevice:(NSString *)errorDomain {
  _device = nil;

  NSError *error = nil;
  if (@available(iOS 10.0, *)) {
    AVCaptureDevicePosition position = [_config.faceMode isEqual:@"back"]
                                           ? AVCaptureDevicePositionBack
                                           : AVCaptureDevicePositionFront;

    NSArray *devices =
        [AVCaptureDeviceDiscoverySession
            discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ]
                                  mediaType:AVMediaTypeVideo
                                   position:position]
            .devices;

    for (AVCaptureDevice *device in devices) {
      if ([device hasMediaType:AVMediaTypeVideo] && device.position == position) {
        _device = device;
        break;
      }
    }

    if (!_device) {
      NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey : @"（capture: no device with that AVMediaTypeVideo exists）"
      };
      error = [NSError errorWithDomain:errorDomain code:-1 userInfo:userInfo];
    }

  } else {
    // Fallback on earlier versions
    NSString *errInfo = @"cannot open camera, iOS version must newer than 10.0";
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errInfo};
    error = [NSError errorWithDomain:errorDomain code:-1 userInfo:userInfo];
  }

  return error;
}

- (NSError *)setupCaptureSession:(NSString *)errorDomain {
  NSError *error = nil;
  _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
  if (error) {
    NSString *errInfo = @"cannot open camera: ";
    [errInfo stringByAppendingFormat:@"%@", error];

    KRYPTON_LLogError(@"camera default get device input failed", [error localizedDescription]);

    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errInfo};
    error = [NSError errorWithDomain:errorDomain code:-1 userInfo:userInfo];
    return error;
  }

  _session = [[AVCaptureSession alloc] init];
  [_session beginConfiguration];

  NSString *resolution = _config.resolution;
  if ([resolution isEqual:@"low"]) {
    _session.sessionPreset = AVCaptureSessionPreset352x288;
  } else if ([resolution isEqual:@"medium"]) {
    _session.sessionPreset = AVCaptureSessionPreset640x480;
  } else if ([resolution isEqual:@"high"]) {
    _session.sessionPreset = AVCaptureSessionPreset1280x720;
  } else {
    _session.sessionPreset = AVCaptureSessionPreset640x480;
  }

  _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
  [_videoOutput setAlwaysDiscardsLateVideoFrames:YES];
  [_videoOutput
      setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)}];
  [_videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

  [_session addInput:_videoInput];
  [_session addOutput:_videoOutput];

  for (AVCaptureConnection *connection in _videoOutput.connections) {
    if (connection.supportsVideoMirroring && _device.position == AVCaptureDevicePositionFront) {
      connection.videoMirrored = YES;
    }

    if (connection.supportsVideoOrientation) {
      connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
  }

  [_session commitConfiguration];
  return nil;
}

- (KryptonCameraConfig *)getCameraConfig {
  return _config;
}

- (void)setDelegate:(id<KryptonCameraDelegate>)delegate {
  _delegate = delegate;
}

- (BOOL)dispose {
  [_session stopRunning];
  _session = nil;

  _delegate = nil;

  _config = nil;
  return YES;
}

- (BOOL)pause {
  if (!_session) {
    return NO;
  }

  [_session stopRunning];
  return YES;
}

- (BOOL)play {
  if (!_session) {
    return NO;
  }

  if (![_session isRunning]) {
    [_session startRunning];
  }
  return YES;
}

- (BOOL)setZoom:(double)zoom {
  if (!_session || _device) {
    return NO;
  }

  if ([_device lockForConfiguration:nil]) {
    AVCaptureDeviceFormat *format = _device.activeFormat;
    // index from maxZoom down to 1.0
    CGFloat maxZoom = format.videoMaxZoomFactor;

    if (zoom < 1.0) {
      zoom = 1.0;
    } else if (zoom > maxZoom) {
      zoom = maxZoom;
    }

    _device.videoZoomFactor = zoom;
    [_device unlockForConfiguration];
  }

  return YES;
}

- (void)captureOutput:(AVCaptureOutput *)output
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
           fromConnection:(AVCaptureConnection *)connection {
  [_delegate cameraDidOutputSampleBuffer:sampleBuffer];
}

@end
