//
//  BDXBridgeServiceManager.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/1/13.
//

#import "BDXBridgeServiceManager.h"
#import <BDAssert/BDAssert.h>

@interface BDXBridgeServiceManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *serviceClasses;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *services;

@end

@implementation BDXBridgeServiceManager

+ (instancetype)sharedManager
{
    static BDXBridgeServiceManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [BDXBridgeServiceManager new];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _serviceClasses = [NSMutableDictionary dictionary];
        _services = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)bindProtocl:(Protocol *)protocol toClass:(Class)klass
{
    if (!klass || !protocol) {
        BDParameterAssert(klass);
        BDParameterAssert(protocol);
        return;
    }
    BDAssert([klass conformsToProtocol:protocol], @"The class '%@' should conforms to protocol '%@'.", NSStringFromClass(klass), NSStringFromProtocol(protocol));

    self.serviceClasses[NSStringFromProtocol(protocol)] = klass;
}

- (nullable id)objectForKeyedSubscript:(Protocol *)protocol
{
    if (!protocol) {
        return nil;
    }
    
    NSString *protocolString = NSStringFromProtocol(protocol);
    id service = self.services[protocolString];
    if (!service) {
        Class serviceClass = self.serviceClasses[protocolString];
        if (serviceClass) {
            service = [serviceClass new];
            self.services[protocolString] = service;
        }
    }
    return service;
}

@end
