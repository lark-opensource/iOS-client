//
//  OKWeakProxy.h
//  Pods
//
//  Created by yanglinfeng on 2019/7/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
 
@interface OKWeakProxy : NSProxy

@property (nonatomic, weak, readonly, nullable) id target;

+ (instancetype)proxyWithTarget:(id)target;

@end

NS_ASSUME_NONNULL_END
