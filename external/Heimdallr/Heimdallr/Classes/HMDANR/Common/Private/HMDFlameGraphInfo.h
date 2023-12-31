//
//  HMDFlameGraphInfo.h
//  Heimdallr
//
//  Created by ByteDance on 2023/3/16.
//

#import <Foundation/Foundation.h>
#import "HMDThreadBacktrace.h"
#import <vector>
#import "hmd_thread_backtrace.h"


NS_ASSUME_NONNULL_BEGIN

@interface HMDFlameGraphInfo : NSObject

@property (nonatomic, copy) NSArray<HMDThreadBacktrace *> *backtraces;

- (instancetype)initWithBacktraces:(std::vector<hmdbt_backtrace_t *>&) bts;
- (NSArray *)reportArray;
- (nullable NSDictionary<NSString*,NSDictionary *> *)reportImages;

@end

NS_ASSUME_NONNULL_END
