#import "LynxSetModule.h"
#import "LynxBaseInspectorOwner.h"
#import "LynxBaseInspectorOwnerNG.h"
#import "LynxContext+Internal.h"
#import "LynxEnv.h"
#import "LynxEnvKey.h"
#if OS_IOS
#import "LynxUIOwner.h"
#endif

@implementation LynxSetModule {
  __weak LynxContext *context_;
}

+ (NSString *)name {
  return @"LynxSetModule";
}

+ (NSDictionary<NSString *, NSString *> *)methodLookup {
  return @{
    @"switchKeyBoardDetect" : NSStringFromSelector(@selector(switchKeyBoardDetect:)),
    @"getLogToSystemStatus" : NSStringFromSelector(@selector(getLogToSystemStatus)),
    @"switchLogToSystem" : NSStringFromSelector(@selector(switchLogToSystem:)),
    @"isAutomationEnabled" : NSStringFromSelector(@selector(isAutomationEnabled)),
    @"switchAutomation" : NSStringFromSelector(@selector(switchAutomation:)),
    @"getEnableLayoutOnly" : NSStringFromSelector(@selector(getEnableLayoutOnly)),
    @"switchEnableLayoutOnly" : NSStringFromSelector(@selector(switchEnableLayoutOnly:)),
    @"getAutoResumeAnimation" : NSStringFromSelector(@selector(getAutoResumeAnimation)),
    @"setAutoResumeAnimation" : NSStringFromSelector(@selector(setAutoResumeAnimation:)),
    @"getEnableNewTransformOrigin" : NSStringFromSelector(@selector(getEnableNewTransformOrigin)),
    @"setEnableNewTransformOrigin" : NSStringFromSelector(@selector(setEnableNewTransformOrigin:)),
  };
}

- (instancetype)initWithLynxContext:(LynxContext *)context {
  self = [super init];
  if (self) {
    context_ = context;
  }
  return self;
}

// Do nothing to align with Android
- (void)switchKeyBoardDetect:(BOOL)arg {
  return;
}

- (NSNumber *)getLogToSystemStatus {
  return @(NO);
}

- (void)switchLogToSystem:(BOOL)arg {
  Class cls = NSClassFromString(@"BDLUtils");
  if (cls == nil) {
    return;
  }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  SEL sel = @selector(logToSystem:);
#pragma clang diagnostic pop
  if ([cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [cls performSelector:sel withObject:[NSNumber numberWithBool:arg]];
#pragma clang diagnostic pop
  }
}

- (BOOL)isAutomationEnabled {
  return [LynxEnv.sharedInstance automationEnabled];
}

- (void)switchAutomation:(BOOL)arg {
  [LynxEnv.sharedInstance setAutomationEnabled:arg];
}

- (BOOL)getEnableLayoutOnly {
  return [LynxEnv.sharedInstance getEnableLayoutOnly];
}

- (void)switchEnableLayoutOnly:(BOOL)arg {
  [LynxEnv.sharedInstance setEnableLayoutOnly:arg];
}

- (BOOL)getAutoResumeAnimation {
  return [LynxEnv.sharedInstance getAutoResumeAnimation];
}

- (void)setAutoResumeAnimation:(BOOL)arg {
  [LynxEnv.sharedInstance setAutoResumeAnimation:arg];
}

- (BOOL)getEnableNewTransformOrigin {
  return [LynxEnv.sharedInstance getEnableNewTransformOrigin];
}

- (void)setEnableNewTransformOrigin:(BOOL)arg {
  [LynxEnv.sharedInstance setEnableNewTransformOrigin:arg];
}
@end
