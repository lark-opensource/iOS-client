//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxContextModule.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxAccessibilityModule : NSObject <LynxContextModule>

- (instancetype)initWithLynxContext:(LynxContext *)context;

@end

NS_ASSUME_NONNULL_END
