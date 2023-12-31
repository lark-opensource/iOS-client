//
//  HMDOTBridge.h
//  Heimdallr
//
//  Created by fengyadong on 2020/11/25.
//

#import <Foundation/Foundation.h>

@class HMDOTTrace;

@interface HMDOTBridge : NSObject

+ (nonnull instancetype)sharedInstance;

/// The global switch, control whether cache the trace according to its traceID
/// @param enabled switch on/off
- (void)enableTraceBinding:(BOOL)enabled;

/// Cache the trace according to its traceID
/// @param trace trace object
/// @param traceID its corresponding traceID
- (void)registerTrace:(nullable HMDOTTrace *)trace forTraceID:(nullable NSString *)traceID;

/// Remove the cached trace according to its traceID
/// @param traceID  its corresponding traceID
- (void)removeTraceID:(nullable NSString *)traceID;

/// Get the trace object by its traceID
/// @param traceID  its corresponding traceID
- (nullable HMDOTTrace *)traceByTraceID:(nullable NSString *)traceID;

@end
