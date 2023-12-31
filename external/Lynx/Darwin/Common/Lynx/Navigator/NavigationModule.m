// Copyright 2019 The Lynx Authors. All rights reserved.

#import "NavigationModule.h"
#import "LynxNavigator.h"

@implementation NavigationModule

- (instancetype)init {
  if (self = [super init]) {
    NSLog(@"NavigationModule alloc");
  }
  return self;
}

+ (NSString *)name {
  return @"NavigationModule";
}

- (void)registerRoute:(NSDictionary *)routeTable {
}

- (void)navigateTo:(NSString *)url param:(NSDictionary *)param {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[LynxNavigator sharedInstance] navigate:url withParam:param];
  });
}

- (void)replace:(NSString *)url param:(NSDictionary *)param {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[LynxNavigator sharedInstance] replace:url withParam:param];
  });
}

- (void)goBack {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[LynxNavigator sharedInstance] goBack];
  });
}

+ (NSDictionary<NSString *, NSString *> *)methodLookup {
  return @{
    @"registerRoute" : NSStringFromSelector(@selector(registerRoute:)),
    @"navigateTo" : NSStringFromSelector(@selector(navigateTo:param:)),
    @"replace" : NSStringFromSelector(@selector(replace:param:)),
    @"goBack" : NSStringFromSelector(@selector(goBack)),
  };
}

@end
