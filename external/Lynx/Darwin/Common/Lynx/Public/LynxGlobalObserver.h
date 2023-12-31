//  Copyright 2023 The Lynx Authors. All rights reserved.

@interface LynxGlobalObserver : NSObject

- (void)notifyAnimationStart;
- (void)notifyAnimationEnd;
- (void)notifyLayout:(NSDictionary*)options;
- (void)notifyScroll:(NSDictionary*)options;
- (void)notifyProperty:(NSDictionary*)options;

@end
