// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxRootUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxUIExposure : NSObject

- (void)setRootUI:(LynxRootUI *)rootUI;
- (void)removeLynxUI:(LynxUI *)ui;
- (BOOL)addLynxUI:(LynxUI *)ui;
- (void)willMoveToWindow:(BOOL)windowIsNil;
- (void)didMoveToWindow:(BOOL)windowIsNil;
- (void)destroyExposure;
- (void)addExposureToRunLoop;
- (void)stopExposure;

@end

NS_ASSUME_NONNULL_END
