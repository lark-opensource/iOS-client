//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#if OS_IOS
#import <Lynx/LynxMemoryListener.h>
#elif OS_OSX
#import <LynxMacOS/LynxMemoryListener.h>
#endif

@interface LynxMemoryController : NSObject <LynxMemoryReporter>

+ (instancetype)shareInstance;

- (void)uploadImageInfo:(NSDictionary*)data;

- (void)startMemoryTracing;

- (void)stopMemoryTracing;

@end
