//
//  BDCTVideoRecordViewController+Camera.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/18.
//

#import "BDCTVideoRecordViewController+Camera.h"
#import "BDCTAdditions.h"
#import <objc/runtime.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import "BDCTEventTracker.h"
#import "BDCTFlow.h"


@implementation BDCTVideoRecordViewController (Camera)

- (AVCaptureVideoPreviewLayer *)previewLayer {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setupCameraSession;
{
    if ([self.cameraSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        [self.cameraSession setSessionPreset:AVCaptureSessionPreset640x480];
    } else {
        [self.cameraSession setSessionPreset:AVCaptureSessionPresetMedium];
    }

    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice bdct_frontCamera] error:&error];
    if (error) {
        [self.bdct_flow.eventTracker trackWithEvent:@"byted_cert_camera_init_error" error:error];
        return;
    }
    if ([self.cameraSession canAddInput:videoInput]) {
        [self.cameraSession addInput:videoInput];
    }

    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:&error];
    if (error) {
        [self.bdct_flow.eventTracker trackWithEvent:@"byted_cert_audio_init_error" error:error];
        return;
    }
    if ([self.cameraSession canAddInput:audioInput]) {
        [self.cameraSession addInput:audioInput];
    }

    AVCaptureVideoDataOutput *videoOutput = [AVCaptureVideoDataOutput new];
    videoOutput.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
    [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    dispatch_queue_t videoOutputQueue = dispatch_queue_create("com.bytedance.cert.videorecord.output.video", DISPATCH_QUEUE_SERIAL);
    // 提高优先级 因为视频可能被丢帧而音频不会
    dispatch_set_target_queue(videoOutputQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    [videoOutput setSampleBufferDelegate:self queue:videoOutputQueue];
    if ([self.cameraSession canAddOutput:videoOutput]) {
        [self.cameraSession addOutput:videoOutput];
    }

    AVCaptureAudioDataOutput *audioOutput = [AVCaptureAudioDataOutput new];
    [audioOutput setSampleBufferDelegate:self queue:dispatch_queue_create("com.bytedance.cert.videorecord.output.audio", DISPATCH_QUEUE_SERIAL)];
    if ([self.cameraSession canAddOutput:audioOutput]) {
        [self.cameraSession addOutput:audioOutput];
    }

    [self.cameraSession bdct_mirrorSetting];
    [self.cameraSession bdct_reorientCamera];

    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.cameraSession];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.frame = [UIScreen mainScreen].bounds;
    [self.view.layer setMasksToBounds:YES];
    [self.view.layer insertSublayer:previewLayer atIndex:0];
    objc_setAssociatedObject(self, @selector(previewLayer), previewLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    return;
}

@end
