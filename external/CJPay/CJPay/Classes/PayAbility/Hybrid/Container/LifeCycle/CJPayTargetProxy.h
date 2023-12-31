//
//  CJPayTargetProxy.h
//  cjpay_hybrid
//
//  Created by shanghuaijun on 2023/3/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayTargetProxy : NSProxy

- (instancetype)init;

- (void)addSubscriber:(id)subscriber;
- (void)removeSubscriber:(id)subscriber;

@end

NS_ASSUME_NONNULL_END
