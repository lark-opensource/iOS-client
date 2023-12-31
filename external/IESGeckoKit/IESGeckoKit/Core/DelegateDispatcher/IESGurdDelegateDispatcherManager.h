//
//  IESGurdDelegateDispatcherManager.h
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define DELEGATE_DISPATCHER(__protocol)         \
(id<__protocol>)[[IESGurdDelegateDispatcherManager sharedManager] dispatcherForProtocol:@protocol(__protocol)] \

@interface IESGurdDelegateDispatcherManager : NSObject

+ (instancetype)sharedManager;

- (id)dispatcherForProtocol:(Protocol *)protocol;

- (void)registerDelegate:(id)delegate forProtocol:(Protocol *)protocol;

- (void)unregisterDelegate:(id)delegate forProtocol:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END
