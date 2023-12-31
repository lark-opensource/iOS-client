//
//  BTDWeakProxy.h
//  Pods
//
//  Created by yanglinfeng on 2019/7/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
 
@interface BTDWeakProxy : NSProxy

@property (nonatomic, weak, readonly, nullable) id target;

+ (instancetype)proxyWithTarget:(id)target;

@end

NS_ASSUME_NONNULL_END
