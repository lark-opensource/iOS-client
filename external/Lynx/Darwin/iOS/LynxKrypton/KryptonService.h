//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "KryptonApp.h"

NS_ASSUME_NONNULL_BEGIN

@protocol KryptonService <NSObject>

@optional
- (void)onBootstrap:(KryptonApp *)app;
- (void)onDestroy;
- (void)onPause;
- (void)onResume;
- (void)onShow;
- (void)onHide;
@end

NS_ASSUME_NONNULL_END
