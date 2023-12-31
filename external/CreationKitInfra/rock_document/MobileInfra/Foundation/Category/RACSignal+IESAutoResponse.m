//
//  RACSignal+IESAutoResponse.m
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/7/6.
//

#import "RACSignal+IESAutoResponse.h"

@implementation RACSignal (IESAutoResponse)

+ (RACSignal *)createSignalWithServiceRegister:(id<IESServiceProvider>)serviceProvider serviceProtocol:(Protocol *)serviceProtocol
{
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        IESBlockDisposable *disposableBlock = [serviceProvider provideBlockNeedServiceResponse:^(id  _Nonnull serviceImpl) {
            if ([serviceImpl conformsToProtocol:serviceProtocol]) {
                [subscriber sendNext:serviceImpl];
                [subscriber sendCompleted];
            } else {
                [subscriber sendError:nil];
            }
        } forProtocol:serviceProtocol];
        
        return [RACDisposable disposableWithBlock:^{
            [disposableBlock dispose];
        }];
    }];
}

@end
