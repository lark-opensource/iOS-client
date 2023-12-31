//
//  HMDWeakProxy.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDWeakProxy<__covariant TargetType> : NSProxy

@property (nullable, nonatomic, weak, readonly) TargetType target;

+ (instancetype)proxyWithTarget:(TargetType _Nullable)target;

- (void)retainTarget;
- (void)releaseTarget;

@end

NS_ASSUME_NONNULL_END
