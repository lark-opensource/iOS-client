//
//  HMDThreadQosWorkerProtocol.h
//  Pods
//
//  Created by xushuangqing on 2022/5/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HMDThreadQosWorkerProtocol <NSObject>

- (void)fishhookWithRebingBlock:(void (^)(struct bd_rebinding *rebindings, size_t rebindings_nel))rebindingBlock;
- (void)launchDidFinished;

@optional
- (NSArray<NSString *>*)markKeyPoint:(NSString *)label;

@end

NS_ASSUME_NONNULL_END
