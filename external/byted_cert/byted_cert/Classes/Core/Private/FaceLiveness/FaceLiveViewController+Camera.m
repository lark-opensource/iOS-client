//
//  FaceLiveViewController+Camera.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/28.
//

#import "FaceLiveViewController+Camera.h"
#import "BDCTAdditions.h"
#import "BDCTFlow.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import "BDCTEventTracker.h"
#import "BytedCertInterface+Logger.h"


@implementation FaceLiveViewController (Camera)

- (void)setupCameraSession {
    dispatch_queue_t queue = dispatch_queue_create("com.bytedance.videoQueue", 0);

    self.cameraSession.sessionPreset = AVCaptureSessionPreset640x480;

    NSError *error = nil;
    BOOL backCamera = [self.bdct_flow.context.finalLivenessType isEqualToString:BytedCertLiveTypeQuality] && self.bdct_flow.context.parameter.backCamera;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:(backCamera ? [AVCaptureDevice bdct_backCamera] : [AVCaptureDevice bdct_frontCamera]) error:&error];
    if (error) {
        BDALOG_PROTOCOL_ERROR_TAG(BytedCertLogTag, @"Init camera error, %@", error);
        [BytedCertInterface logWithErrorInfo:@"byted_cert init camera fail" params:nil error:error];
        [self.bdct_flow.eventTracker trackWithEvent:@"byted_cert_camera_init_error" error:error];
        return;
    }
    if (videoInput != nil && [self.cameraSession canAddInput:videoInput]) {
        [self.cameraSession addInput:videoInput];
    }
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoOutput.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
    [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    if ([self.cameraSession canAddOutput:videoOutput]) {
        [self.cameraSession addOutput:videoOutput];
    }
    [videoOutput setSampleBufferDelegate:self queue:queue];

    if ([[self.bdct_flow.context.liveDetectRequestParams btd_stringValueForKey:BytedCertLivenessType] isEqualToString:BytedCertLiveTypeVideo]) {
        self.cameraSession.sessionPreset = AVCaptureSessionPreset1280x720;
        //audio
        AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:&error];
        if (error) {
            BDALOG_PROTOCOL_ERROR_TAG(BytedCertLogTag, @"Init audio record error, %@", error);
            [BytedCertInterface logWithErrorInfo:@"byted_cert init audio fail" params:nil error:error];
            [self.bdct_flow.eventTracker trackWithEvent:@"byted_cert_camera_init_error" error:error];
            return;
        }
        if ([self.cameraSession canAddInput:audioInput]) {
            [self.cameraSession addInput:audioInput];
        }
        AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        if ([self.cameraSession canAddOutput:audioOutput]) {
            [self.cameraSession addOutput:audioOutput];
        }
        [audioOutput setSampleBufferDelegate:self queue:queue];
    }
    if (!self.bdct_flow.context.parameter.backCamera) {
        [self.cameraSession bdct_mirrorSetting];
    }
    [self.cameraSession bdct_reorientCamera];
    return;
}

- (void)cameraSessionDidStartRunning:(NSNotification *)notification {
    if ([BytedCertManager respondsToSelector:@selector(metaSecReportForOnCameraRunning)]) {
        [BytedCertManager performSelector:@selector(metaSecReportForOnCameraRunning)];
    }
}

@end
