// Copyright 2023 The Lynx Authors. All rights reserved.
#import "LynxExposureModule.h"
#import "LynxContext+Internal.h"
#import "LynxContext.h"
#import "LynxUIContext.h"
#import "LynxUIExposure.h"
#import "LynxUIOwner.h"

using namespace lynx;

@implementation LynxExposureModule {
  __weak LynxContext *context_;
}

- (instancetype)initWithLynxContext:(LynxContext *)context {
  self = [super init];
  if (self) {
    context_ = context;
  }

  return self;
}

+ (NSString *)name {
  return @"LynxExposureModule";
}

+ (NSDictionary<NSString *, NSString *> *)methodLookup {
  return @{
    @"stopExposure" : NSStringFromSelector(@selector(stopExposure)),
    @"resumeExposure" : NSStringFromSelector(@selector(resumeExposure))
  };
}

typedef void (^LynxExposureBlock)(LynxExposureModule *);

- (void)runOnUIThreadSafely:(LynxExposureBlock)block {
  __weak LynxExposureModule *weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    if (weakSelf) {
      __strong LynxExposureModule *strongSelf = weakSelf;
      if (strongSelf->context_) {
        block(strongSelf);
      }
    }
  });
}

// stop exposure detection, send disexposure event for all exposed ui.
// called by frontend
- (void)stopExposure {
  [self runOnUIThreadSafely:^(LynxExposureModule *target) {
    LynxUIExposure *exposure = [self exposure];
    [exposure stopExposure];
  }];
}

// resume exposure detection, send exposure event for all exposed ui on screen.
// called by frontend
- (void)resumeExposure {
  [self runOnUIThreadSafely:^(LynxExposureModule *target) {
    LynxUIExposure *exposure = [self exposure];
    [exposure addExposureToRunLoop];
  }];
}

- (LynxUIExposure *)exposure {
  return context_.uiOwner.uiContext.uiExposure;
}

@end
