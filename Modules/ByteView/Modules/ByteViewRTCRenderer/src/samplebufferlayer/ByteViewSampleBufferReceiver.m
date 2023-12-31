//
//  ByteViewSampleBufferReceiver.m
//  ByteViewRTCRenderer
//
//  Created by FakeGourmet on 2023/9/14.
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import <CoreMedia/CoreMedia.h>
#import "ByteViewSampleBufferReceiver.h"
#import "ByteViewSampleBufferLayerView.h"

@implementation ByteViewSampleBufferLayerReceiver

- (instancetype)init {
    self = [super init];
    return self;
}

- (void)renderFrame:(nullable ByteViewVideoFrame *)videoFrame {
    if (!videoFrame)
        return;
    if (NSThread.isMainThread) {
        [self _renderFrame:videoFrame];
        [self.parent layoutIfNeeded];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _renderFrame:videoFrame];
        });
    }
}

- (void)_renderFrame:(ByteViewVideoFrame *)videoFrame {

    assert(NSThread.isMainThread);

    if (!self.parent) {
        return;
    }

    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];

    AVSampleBufferDisplayLayer* sampleBufferLayer = (AVSampleBufferDisplayLayer*)self.parent.layer;
    CMSampleBufferRef sampleBuffer = [self transform:videoFrame.pixelBuffer timestamp:videoFrame.timeStampNs];

    if (!sampleBufferLayer || !sampleBuffer || !sampleBufferLayer.isReadyForMoreMediaData) {
        return;
    }

    if (sampleBufferLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
        [sampleBufferLayer flush];
    }

    [sampleBufferLayer enqueueSampleBuffer:sampleBuffer];
    [sampleBufferLayer setContentsRect:videoFrame.cropRect];
    [sampleBufferLayer setTransform:[self calculateTransform:videoFrame]];

    int duration = [[NSDate date] timeIntervalSince1970] - start;

    [self.parent.renderElapseObserver reportRenderElapse:duration];
}

- (nullable CMSampleBufferRef)transform:(CVPixelBufferRef)pixelBuffer timestamp:(int64_t)timestamp {
    if (!pixelBuffer) {
        return nil;
    }

    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);

    if (result != 0 || !videoInfo) {
        return nil;
    }

    // 设置 kCMSampleAttachmentKey_DisplayImmediately 后 presentationTimeStamp 失效
    CMTime presentationTimeStamp = CMTimeMake(timestamp, 1e9);
    CMSampleTimingInfo timing = { kCMTimeInvalid, presentationTimeStamp, kCMTimeInvalid };

    CMSampleBufferRef sampleBuffer = NULL;
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timing, &sampleBuffer);

    if (result != 0 || !sampleBuffer) {
        return nil;
    }

    if (videoInfo) {
        CFRelease(videoInfo);
    }

    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    CMSetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_EndsPreviousSampleDuration, kCFBooleanTrue, kCMAttachmentMode_ShouldPropagate);

    return (CMSampleBufferRef)CFAutorelease(sampleBuffer);
}

- (CATransform3D)calculateTransform:(ByteViewVideoFrame*)videoFrame {
    CATransform3D rotateTransform = CATransform3DMakeRotation(0, 0, 0, 0);
    switch (videoFrame.rotation) {
        case ByteViewVideoRotation_0:
            rotateTransform = CATransform3DMakeRotation(0, 0, 0, 1);
            break;
        case ByteViewVideoRotation_90:
            rotateTransform = CATransform3DMakeRotation(M_PI_2, 0, 0, 1);
            break;
        case ByteViewVideoRotation_180:
            rotateTransform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
            break;
        case ByteViewVideoRotation_270:
            rotateTransform = CATransform3DMakeRotation(M_PI_2, 0, 0, -1);
            break;
    }
    CATransform3D filpTransform = CATransform3DMakeScale(1, 1, 1);
    if (videoFrame.flip) {
        if (videoFrame.flipHorizontal) {
            filpTransform = CATransform3DMakeScale(-1, 1, 1);
        } else {
            filpTransform = CATransform3DMakeScale(1, -1, 1);
        }
    }
    return CATransform3DConcat(rotateTransform, filpTransform);
}

@end
