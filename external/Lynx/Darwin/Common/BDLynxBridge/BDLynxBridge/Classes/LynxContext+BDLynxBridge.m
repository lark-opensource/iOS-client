// Copyright 2021 The Lynx Authors. All rights reserved.

#import <objc/runtime.h>
#import "BDLynxBridge+Internal.h"
#import "LynxContext+BDLynxBridge.h"
#import "LynxLazyLoad.h"

static void BDLynxClassSwizzle(Class class, SEL originalSelector, SEL swizzledSelector) {
  Method originalMethod = class_getInstanceMethod(class, originalSelector);
  Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

  BOOL didAddMethod =
      class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod),
                      method_getTypeEncoding(swizzledMethod));

  if (didAddMethod) {
    class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod),
                        method_getTypeEncoding(originalMethod));
  } else {
    method_exchangeImplementations(originalMethod, swizzledMethod);
  }
}

@implementation LynxContext (BDLynxBridge)

LYNX_LOAD_LAZY(BDLynxClassSwizzle(self.class, NSSelectorFromString(@"dealloc"),
                                  @selector(BDLynxBridge_dealloc));)

- (void)BDLynxBridge_dealloc {
  if (self.containerID != nil) {
    NSString *containerID = self.containerID;
    // Do not operate BDLynxBridgesPool synchronously in dealloc. It can cause deadlock problems.
    dispatch_async(dispatch_get_main_queue(), ^{
      [BDLynxBridgesPool setBridge:nil forContainerID:containerID];
    });
  }
  [self BDLynxBridge_dealloc];
}

- (NSString *)containerID {
  return objc_getAssociatedObject(self, @"containerID");
}

- (void)setContainerID:(NSString *)containerID {
  objc_setAssociatedObject(self, @"containerID", containerID, OBJC_ASSOCIATION_COPY);
}

@end
