//
//  LivenessTaskController.m
//  Pods
//
//  Created by zhengyanxin on 2020/12/22.
//

#import <Foundation/Foundation.h>
#import "LivenessTaskController.h"
#import <BDAssert/BDAssert.h>

#define AbstractMethodNotImplemented() BDAssert(NO, @"You must override %@ in a subclass.", NSStringFromSelector(_cmd))


@implementation LivenessTC : NSObject

#pragma mark - required

- (instancetype)initWithVC:(UIViewController *)vc {
    BDAssert(![self isMemberOfClass:[LivenessTC class]], @"LivenessTC is an abstract class, you should not instantiate it directly.");

    return [super init];
}

- (int)setInitParams:(NSDictionary *)params {
    AbstractMethodNotImplemented();
    return -1;
}

- (int)setParamsGeneral:(int)type value:(float)value {
    AbstractMethodNotImplemented();
    return -1;
}

- (CGImageRef)doFaceLive:(CVPixelBufferRef)pixels orient:(ScreenOrient)orient {
    AbstractMethodNotImplemented();
    return nil;
}

- (void)setMaskRadiusRatio:(float)maskRadiusRadio offsetToCenterRatio:(float)offsetToCenterRatio {
    AbstractMethodNotImplemented();
}

- (void)reStart:(int)type {
    AbstractMethodNotImplemented();
}

- (void)viewDismiss {
    AbstractMethodNotImplemented();
}

- (void)trackCancel {
    AbstractMethodNotImplemented();
}

- (int)getAlgoErrorCode {
    AbstractMethodNotImplemented();
    return -1;
}

- (NSString *)getLivenessErrorTitle:(int)code {
    AbstractMethodNotImplemented();
    return nil;
}

#pragma mark - optional

- (NSString *)getLivenessErrorMsg:(int)code {
    return nil;
}

- (void)recordSrcVideo:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
}

@end
