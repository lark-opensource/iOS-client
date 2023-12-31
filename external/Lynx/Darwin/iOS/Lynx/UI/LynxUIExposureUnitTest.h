//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxUIExposure+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxUIExposureDetail : NSObject
@end

@interface LynxUIExposure ()

@property(nonatomic) NSMutableSet<LynxUIExposureDetail *> *uiInWindowMapBefore;

- (void)removeFromRunLoop;

- (void)sendEvent:(NSMutableSet<LynxUIExposureDetail *> *)uiSet eventName:(NSString *)eventName;

@end

NS_ASSUME_NONNULL_END
