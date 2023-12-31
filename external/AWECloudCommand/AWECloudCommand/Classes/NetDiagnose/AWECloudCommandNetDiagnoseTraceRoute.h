//
//  AWECloudCommandNetDiagnoseTraceRoute.h
//  AWELive
//
//  Created by songxiangwu on 2018/4/16.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWECloudCommandNetDiagnoseTraceRouteDelegate <NSObject>

- (void)didAppendTraceRouteLog:(NSString *)log;
- (void)didFinishTraceRoute;

@end


@interface AWECloudCommandNetDiagnoseTraceRoute : NSObject

@property (nonatomic, weak) id<AWECloudCommandNetDiagnoseTraceRouteDelegate> delegate;

- (instancetype)initWithMaxTTL:(NSInteger)ttl timeout:(NSInteger)timeout maxAttempts:(NSInteger)attempts port:(NSInteger)port;
- (BOOL)doTraceRoute:(NSString *)host;
- (void)stopTrace;
- (BOOL)isTracingRoute;

@end

NS_ASSUME_NONNULL_END
