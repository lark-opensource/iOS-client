//
//  AVCaptureSession+BDCTAdditions.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/31.
//

#import "AVCaptureSession+BDCTAdditions.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>


@implementation AVCaptureSession (BDCTAdditions)

- (void)bdct_reorientCamera {
    NSInteger orientation = [[UIApplication sharedApplication] statusBarOrientation];

    for (AVCaptureVideoDataOutput *output in self.outputs) {
        for (AVCaptureConnection *av in output.connections) {
            if (![av isVideoOrientationSupported]) {
                break;
            }
            if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
                if (av.videoOrientation != AVCaptureVideoOrientationPortrait) {
                    av.videoOrientation = AVCaptureVideoOrientationPortrait;
                }
                continue;
            }
            switch (orientation) {
                case UIInterfaceOrientationPortraitUpsideDown:
                    if (av.videoOrientation != AVCaptureVideoOrientationPortraitUpsideDown) {
                        av.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                    }
                    break;
                case UIInterfaceOrientationLandscapeRight:
                    if (av.videoOrientation != AVCaptureVideoOrientationLandscapeRight) {
                        av.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                    }
                    break;
                case UIInterfaceOrientationLandscapeLeft:
                    if (av.videoOrientation != AVCaptureVideoOrientationLandscapeLeft) {
                        av.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
                    }
                    break;
                case UIInterfaceOrientationPortrait:
                    if (av.videoOrientation != AVCaptureVideoOrientationPortrait) {
                        av.videoOrientation = AVCaptureVideoOrientationPortrait;
                    }
                    break;
                default:
                    break;
            }
        }
    }
}

- (void)bdct_mirrorSetting {
    for (AVCaptureVideoDataOutput *output in self.outputs) {
        if ([output isKindOfClass:AVCaptureVideoDataOutput.class]) {
            for (AVCaptureConnection *av in output.connections) {
                if ([av isKindOfClass:AVCaptureConnection.class] && av.isVideoMirroringSupported) {
                    [av setVideoMirrored:YES];
                }
            }
        }
    }
}

- (void)bdct_startRunning {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self respondsToSelector:@selector(bdctbpea_startRunning)]) {
        [self performSelector:@selector(bdctbpea_startRunning)];
    } else {
        [self startRunning];
    }
#pragma clang diagnostic pop
}

- (void)bdct_stopRunning {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self respondsToSelector:@selector(bdctbpea_stopRunning)]) {
        [self performSelector:@selector(bdctbpea_stopRunning)];
    } else {
        [self stopRunning];
    }
#pragma clang diagnostic pop
}

@end
