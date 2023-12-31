//
//  BDWebViewOfflineManager.h
//  BDWebKit
//
//  Created by wealong on 2020/1/5.
//

#import <Foundation/Foundation.h>
#import <BDWebKit/IESFalconCustomInterceptor.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDWebViewOfflineManager : NSObject

@property (nonatomic, class, assign) BOOL interceptionEnable;

+ (instancetype)sharedInstance;

+ (void)registerCustomInterceptor:(id<IESFalconCustomInterceptor>)interceptor;
+ (void)unregisterCustomInterceptor:(id<IESFalconCustomInterceptor>)interceptor;

+ (void)registerCustomInterceptorList:(NSArray<IESFalconCustomInterceptor> *)interceptorList;
+ (void)unregisterCustomInterceptorList:(NSArray<IESFalconCustomInterceptor> *)interceptorList;

@end

NS_ASSUME_NONNULL_END
