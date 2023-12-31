//
//  PNSBacktraceProtocol.h
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/15.
//

#import "PNSServiceCenter.h"

#ifndef PNSBacktraceProtocol_h
#define PNSBacktraceProtocol_h

#define PNSBacktrace PNS_GET_INSTANCE(PNSBacktraceProtocol)

@protocol PNSBacktraceProtocol <NSObject>

- (NSArray * _Nullable)getBacktracesWithSkippedDepth:(NSUInteger)skippedDepth
                                      needAllThreads:(BOOL)needAllThreads;

- (void)getFormatBacktracesWithNeedAllThreads:(BOOL)needAllThreads
                                     callback:(void (^ _Nonnull)(BOOL success, NSString * _Nonnull formatBacktraces))callback;

- (NSString * _Nullable)formatBacktraces:(NSArray *_Nonnull)backtraces;

- (NSArray <NSNumber *> * _Nullable)getCurrentBacktraceAddressesWithSkippedDepth:(NSUInteger)skippedDepth;

- (NSArray * _Nullable)mergeBacktracesWithFirst:(NSArray *_Nonnull)firstBacktraces second:(NSArray *_Nonnull)secondBacktraces;

- (uintptr_t)getImageHeaderAddressWithName:(NSString * _Nullable)name;

- (BOOL)isMultipleAsyncStackTraceEnabled;

- (BOOL)isSameBacktracesWithFirst:(NSArray * _Nullable)firstBacktraces second:(NSArray * _Nullable)secondBacktraces;

@end

#endif /* PNSBacktraceProtocol_h */
