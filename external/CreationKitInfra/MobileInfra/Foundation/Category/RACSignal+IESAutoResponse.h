//
//  RACSignal+IESAutoResponse.h
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/7/6.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <IESInject/IESInject.h>

NS_ASSUME_NONNULL_BEGIN

@interface RACSignal (IESAutoResponse)

+ (RACSignal *)createSignalWithServiceRegister:(id<IESServiceProvider>)serviceProvider serviceProtocol:(Protocol *)serviceProtocol;

@end

NS_ASSUME_NONNULL_END
