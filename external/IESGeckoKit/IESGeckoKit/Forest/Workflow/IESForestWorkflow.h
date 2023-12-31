// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestBaseFetcher.h"
#import "IESForestDefines.h"

NS_ASSUME_NONNULL_BEGIN
@interface IESForestWorkflow : NSObject

@property (nonatomic, strong) IESForestRequest *request;
@property (nonatomic, weak) IESForestKit *forestKit;

/// create a workflow
- (instancetype)initWithFetchers:(NSArray<id<IESForestFetcherProtocol>> *)fetchers request:(IESForestRequest *)request;

/// cancel fetch - the following fetchers will not be executed
- (BOOL)cancelFetch;

- (void)fetchResourceWithCompletion:(IESForestCompletionHandler)completion;

- (nullable NSString *)debugInfo;

- (NSString *)fetcherNames;

@end

NS_ASSUME_NONNULL_END
