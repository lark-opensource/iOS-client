//
//  BDPWeakProxy.h
//  Timor
//
//  Created by 王浩宇 on 2018/11/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPWeakProxy : NSProxy

@property (nonatomic, weak, nullable) id object;

+ (nullable instancetype)weakProxy:(id)object;

@end


@interface NSObject (BDPWeakProxy)

/// 当前对象的WeakProxy, Not thread safe!!!
@property (nonatomic, readonly, strong) BDPWeakProxy *bdp_weakProxy;

@end

NS_ASSUME_NONNULL_END
