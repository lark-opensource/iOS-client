// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class IESForestRequest;
@protocol IESForestResponseProtocol;

// Refs: https://bytedance.feishu.cn/docs/doccn4R5TDrPJffRP6LwNJYrU5b
@interface IESForestEventTrackData : NSObject

- (instancetype)initWithRequest:(IESForestRequest *)request
                       response:(id<IESForestResponseProtocol>)response;

@property (nonatomic, assign) BOOL isTemplate;
@property (nonatomic, assign) BOOL isSuccess;

@property (nonatomic, copy) NSDictionary *loaderInfo;
@property (nonatomic, copy) NSDictionary *errorInfo;
@property (nonatomic, copy) NSDictionary *resourceInfo;
@property (nonatomic, copy) NSDictionary *metricInfo;
@property (nonatomic, copy) NSDictionary *extraInfo;
@property (nonatomic, readonly) NSDictionary *calculatedMetricInfo;

@end

NS_ASSUME_NONNULL_END
