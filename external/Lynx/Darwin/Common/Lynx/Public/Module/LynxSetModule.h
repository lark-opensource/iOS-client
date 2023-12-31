// Copyright 2020 The Lynx Authors. All rights reserved.

#import "LynxContextModule.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxSetModule : NSObject <LynxContextModule>

- (instancetype)initWithLynxContext:(LynxContext *)context;

- (void)switchKeyBoardDetect:(BOOL)arg;

- (BOOL)getEnableLayoutOnly;

- (void)switchEnableLayoutOnly:(BOOL)arg;

- (BOOL)getAutoResumeAnimation;

- (void)setAutoResumeAnimation:(BOOL)arg;

- (BOOL)getEnableNewTransformOrigin;

- (void)setEnableNewTransformOrigin:(BOOL)arg;

@end

NS_ASSUME_NONNULL_END
