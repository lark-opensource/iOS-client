// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestFetcherProtocol.h"
@class IESForestRequest;
@class IESForestKit;

NS_ASSUME_NONNULL_BEGIN

@interface IESForestBaseFetcher : NSObject <IESForestFetcherProtocol>

@property (nonatomic, assign) BOOL isCanceled;
@property (nonatomic, strong) IESForestRequest *request;
@property (nonatomic, weak) IESForestKit *forestKit;

@end

NS_ASSUME_NONNULL_END
