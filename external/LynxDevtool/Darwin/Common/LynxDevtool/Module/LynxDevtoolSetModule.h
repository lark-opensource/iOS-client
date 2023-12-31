//  Copyright 2023 The Lynx Authors. All rights reserved.

#if OS_IOS
#import <Lynx/LynxContextModule.h>
#elif OS_OSX
#import <LynxMacOS/LynxContextModule.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface LynxDevtoolSetModule : NSObject <LynxContextModule>

- (instancetype)initWithLynxContext:(LynxContext *)context;

@end

NS_ASSUME_NONNULL_END
