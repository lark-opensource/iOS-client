//  Copyright 2023 The Lynx Authors. All rights reserved.
#import "LynxContextModule.h"
#import "LynxExposureModule.h"
#import "LynxUIExposureUnitTest.h"

@interface LynxExposureModule ()
- (LynxUIExposure *)exposure;
- (void)stopExposure;
- (void)resumeExposure;
typedef void (^LynxExposureBlock)(LynxExposureModule *);
- (void)runOnUIThreadSafely:(LynxExposureBlock)block;
@end
