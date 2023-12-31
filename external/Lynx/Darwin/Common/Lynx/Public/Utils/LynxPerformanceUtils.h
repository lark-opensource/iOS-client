//
//  LynxPerformanceUtils.h
//  Indexer
//
//  Created by bytedance on 2021/12/6.
//

#ifndef DARWIN_COMMON_LYNX_UTILS_LYNXPERFORMANCEUTILS_H_
#define DARWIN_COMMON_LYNX_UTILS_LYNXPERFORMANCEUTILS_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxPerformanceUtils : NSObject

+ (NSDictionary *)memoryStatus;
+ (uint64_t)availableMemory;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_UTILS_LYNXPERFORMANCEUTILS_H_
