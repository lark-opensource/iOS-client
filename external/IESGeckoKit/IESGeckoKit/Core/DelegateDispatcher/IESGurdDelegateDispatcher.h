//
//  IESGurdDelegateDispatcher.h
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdDelegateDispatcher : NSObject

+ (instancetype)dispatcherWithProtocol:(Protocol *)protocol;

- (void)registerDelegate:(id)delegate;

- (void)unregisterDelegate:(id)delegate;

@end

NS_ASSUME_NONNULL_END
