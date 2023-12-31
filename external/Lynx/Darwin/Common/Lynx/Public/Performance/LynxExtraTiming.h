//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_PERFORMANCE_LYNXEXTRATIMING_H_
#define DARWIN_COMMON_LYNX_PERFORMANCE_LYNXEXTRATIMING_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxExtraTiming : NSObject

@property(nonatomic, assign) uint64_t openTime;
@property(nonatomic, assign) uint64_t containerInitStart;
@property(nonatomic, assign) uint64_t containerInitEnd;
@property(nonatomic, assign) uint64_t prepareTemplateStart;
@property(nonatomic, assign) uint64_t prepareTemplateEnd;

- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_PERFORMANCE_LYNXEXTRATIMING_H_
