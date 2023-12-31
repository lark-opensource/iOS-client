// Copyright 2020 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDLReportProtocol <NSObject>

+ (instancetype)sharedInstance;
@optional

- (void)launchSession;

- (void)reportException:(NSError *)error;

- (NSString *)backtraceWithMessage:(NSString *)message bySkippedDepth:(NSUInteger)skippedDepth;

@end

NS_ASSUME_NONNULL_END
