//
//  LynxView+Bridge.m
//
//  Created by li keliang on 2020/2/9.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import <objc/runtime.h>
#import "BDLynxBridge+Internal.h"
#import "BDLynxBridgeModule.h"
#import "LynxContext+BDLynxBridge.h"
#import "LynxLazyLoad.h"
#import "LynxView+Bridge.h"

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

@implementation LynxView (Bridge)

+ (void)load {
  BDLynxClassSwizzle(self.class, @selector(initWithBuilderBlock:),
                     @selector(BDLynxBridge_initWithBuilderBlock:));
  BDLynxClassSwizzle(self.class, @selector(loadTemplateFromURL:initData:),
                     @selector(BDLynxBridge_loadTemplateFromURL:initData:));
  BDLynxClassSwizzle(self.class, @selector(loadTemplate:withURL:initData:),
                     @selector(BDLynxBridge_loadTemplate:withURL:initData:));
  BDLynxClassSwizzle(self.class, @selector(processLayout:withURL:initData:),
                     @selector(BDLynxBridge_processLayout:withURL:initData:));
  BDLynxClassSwizzle(self.class, @selector(clearForDestroy),
                     @selector(BDLynxBridge_clearForDestroy));
  BDLynxClassSwizzle(self.class, @selector(attachTemplateRender:),
                     @selector(BDLynxBridge_attachTemplateRender:));
}

- (instancetype)BDLynxBridge_initWithBuilderBlock:(void (^)(__attribute__((noescape))
                                                            LynxViewBuilder *_Nonnull))block {
  __weak __typeof(self) weakSelf = self;
  return [self BDLynxBridge_initWithBuilderBlock:^(LynxViewBuilder *_Nonnull innerBuilder) {
    !block ?: block(innerBuilder);
    [innerBuilder.config registerModule:BDLynxBridgeModule.class
                                  param:@{
                                    @"containerID" : weakSelf.containerID,
                                    @"namescope" : weakSelf.namescope ?: @""
                                  }];
    return;
  }];
}

- (void)initGlobalProps:(LynxTemplateData *)data {
  // Prefer to use globalProps TemplateData to imporve perf
  if (self.bridge.globalPropsData) {
    LynxTemplateData *globalData = self.bridge.globalPropsData;
    [globalData updateObject:self.containerID forKey:@"containerID"];
    [self updateGlobalPropsWithTemplateData:globalData];
  } else {
    NSMutableDictionary *globalProps =
        [NSMutableDictionary dictionaryWithDictionary:self.bridge.globalProps];
    globalProps[@"containerID"] = self.containerID;
    [self updateGlobalPropsWithDictionary:globalProps];
  }
}

- (void)BDLynxBridge_loadTemplateFromURL:(NSString *)url initData:(LynxTemplateData *)data {
  [self initGlobalProps:data];
  [self BDLynxBridge_loadTemplateFromURL:url initData:data];
}

- (void)BDLynxBridge_loadTemplate:(NSData *)tem
                          withURL:(NSString *)url
                         initData:(LynxTemplateData *)data {
  [self initGlobalProps:data];
  [self BDLynxBridge_loadTemplate:tem withURL:url initData:data];
}

- (void)BDLynxBridge_processLayout:(NSData *)tem
                           withURL:(NSString *)url
                          initData:(LynxTemplateData *)data {
  [self initGlobalProps:data];
  [self BDLynxBridge_processLayout:tem withURL:url initData:data];
}

- (void)BDLynxBridge_clearForDestroy {
  if (!self.isLynxViewBeingDestroyed) {
    LynxContext *lynxContext = [self getLynxContext];
    if (lynxContext) {
      // If LynxContext is alive, set container id to LynxContext and LynxContext will release
      // bridge in its dealloc.
      [lynxContext setContainerID:self.containerID];
      // There will still be JSB calls after LynxView is destroyed, and namespace is required at
      // this time, so we save the namespace in BDLynxBridge when LynxView is destroyed, so that the
      // correct namespace can be obtained when JSB is called after LynxView is destroyed.
      BDLynxBridge *bdLynxBridge = objc_getAssociatedObject(self, @selector(bridge));
      if (bdLynxBridge != nil && self.namescope != nil) {
        bdLynxBridge.namescope = self.namescope;
      }
    } else {
      // release bridge
      NSString *containerID = self.containerID;
      // Do not operate BDLynxBridgesPool synchronously in dealloc. It can cause deadlock problems.
      dispatch_async(dispatch_get_main_queue(), ^{
        [BDLynxBridgesPool setBridge:nil forContainerID:containerID];
      });
    }
  }
  self.isLynxViewBeingDestroyed = YES;
  [self BDLynxBridge_clearForDestroy];
}

- (void)BDLynxBridge_attachTemplateRender:(LynxTemplateRender *_Nullable)templateRender {
  if (templateRender && ![templateRender isModuleExist:BDLynxBridgeModule.name]) {
    [templateRender
        registerModule:BDLynxBridgeModule.class
                 param:@{@"containerID" : self.containerID, @"namescope" : self.namescope ?: @""}];
  }
  [self BDLynxBridge_attachTemplateRender:templateRender];
}
#pragma mark - Accessors

- (BDLynxBridge *)bridge {
  BDLynxBridge *bridge = objc_getAssociatedObject(self, _cmd);
  if (!bridge) {
    bridge = [[BDLynxBridge alloc] initWithLynxView:self];
    [BDLynxBridgesPool setBridge:bridge forContainerID:self.containerID];
    ;
    objc_setAssociatedObject(self, _cmd, bridge, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return bridge;
}

- (void)setBridge:(BDLynxBridge *)bridge {
  if (bridge) {
    objc_setAssociatedObject(self, _cmd, bridge, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
}

- (NSString *)namescope {
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setNamescope:(NSString *)namescope {
  objc_setAssociatedObject(self, @selector(namescope), namescope, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)isLynxViewBeingDestroyed {
  NSNumber *number = objc_getAssociatedObject(self, _cmd);
  if (number == nil) {
    return NO;
  }
  return [number boolValue];
}

- (void)setIsLynxViewBeingDestroyed:(BOOL)isLynxViewBeingDestroyed {
  NSNumber *number = [NSNumber numberWithBool:isLynxViewBeingDestroyed];
  objc_setAssociatedObject(self, @selector(isLynxViewBeingDestroyed), number,
                           OBJC_ASSOCIATION_RETAIN);
}

@end

@implementation LynxView (ID)

- (NSString *)containerID {
  NSString *containerID = objc_getAssociatedObject(self, @"containerID");
  if (!containerID) {
    containerID = [NSUUID UUID].UUIDString;
    objc_setAssociatedObject(self, @"containerID", containerID, OBJC_ASSOCIATION_COPY_NONATOMIC);
  }
  return containerID;
}

- (void)setContainerID:(NSString *)containerID {
  objc_setAssociatedObject(self, @"containerID", containerID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@implementation LynxView (Initializer)

- (instancetype)initWithContainerSelfBuilderBlock:
    (void (^)(__attribute__((noescape))LynxViewBuilder *_Nonnull, LynxView *_Nonnull))block {
  __weak __typeof(self) weakSelf = self;
  return [self initWithBuilderBlock:^(LynxViewBuilder *_Nonnull builder) {
    !block ?: block(builder, weakSelf);
  }];
}

- (instancetype)initWithContainerBuilderBlock:
    (void (^)(__attribute__((noescape))LynxViewBuilder *_Nonnull, NSString *_Nonnull))block {
  __weak __typeof(self) weakSelf = self;
  return [self initWithBuilderBlock:^(LynxViewBuilder *_Nonnull builder) {
    !block ?: block(builder, weakSelf.containerID);
  }];
}

- (instancetype)initWithContainer:(NSString *)container
                 withBuilderBlock:(void (^)(__attribute__((noescape))LynxViewBuilder *_Nonnull,
                                            NSString *_Nonnull))block {
  __weak __typeof(self) weakSelf = self;
  if (container != nil) {
    self.containerID = container;
  }
  return [self initWithBuilderBlock:^(LynxViewBuilder *_Nonnull builder) {
    !block ?: block(builder, weakSelf.containerID);
  }];
}

@end
