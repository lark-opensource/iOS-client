//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "KryptonLoaderService.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxKryptonLoader : NSObject <KryptonLoaderService>
- (void)setRuntimeId:(NSInteger)runtimeId;
@end

NS_ASSUME_NONNULL_END
