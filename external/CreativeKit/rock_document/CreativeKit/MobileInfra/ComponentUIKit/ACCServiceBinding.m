//
//  ACCServiceBinding.m
//  CreativeKit-Pods-Aweme
//
//  Created by Liu Deping on 2021/1/8.
//

#import "ACCServiceBinding.h"

@interface ACCServiceBinding ()

@property (nonatomic, strong) Protocol *serciceProtocol;
@property (nonatomic, strong) NSArray<Protocol *> *serciceProtocols;
@property (nonatomic, strong) id serviceImpl;

@end

@implementation ACCServiceBinding

@end

ACCServiceBinding *ACCCreateServiceBinding(Protocol *serviceProtocol, id serviceImpl)
{
    if ([serviceImpl conformsToProtocol:serviceProtocol]) {
        ACCServiceBinding *serviceBinding = [[ACCServiceBinding alloc] init];
        serviceBinding.serciceProtocol = serviceProtocol;
        serviceBinding.serviceImpl = serviceImpl;
        return serviceBinding;
    }
    return nil;
}

ACCServiceBinding *ACCCreateMutipleServiceBinding(NSArray<Protocol *> *serviceProtocols, id serviceImpl)
{
    __block BOOL rightImpl = YES;
    [serviceProtocols enumerateObjectsUsingBlock:^(Protocol * _Nonnull protocol, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![serviceImpl conformsToProtocol:protocol]) {
            rightImpl = NO;
            *stop = YES;
        }
    }];
    
    if (rightImpl) {
        ACCServiceBinding *mutipleServiceBinding = [[ACCServiceBinding alloc] init];
        mutipleServiceBinding.serciceProtocols = serviceProtocols;
        mutipleServiceBinding.serviceImpl = serviceImpl;
        return mutipleServiceBinding;
    }
    
    return nil;
}
