//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LynxUITarget <NSObject>
@optional
- (void)targetOnScreen;
- (void)freeMemoryCache;
- (void)targetOffScreen;
@end

NS_ASSUME_NONNULL_END
