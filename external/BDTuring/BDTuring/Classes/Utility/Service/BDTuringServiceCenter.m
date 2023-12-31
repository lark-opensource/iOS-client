//
//  BDTuringServiceCenter.m
//  BDTuring
//
//  Created by bob on 2019/9/18.
//

#import "BDTuringServiceCenter.h"
#import "BDTuringService.h"
#import "BDTuringMacro.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringVerifyModel+Result.h"
#import "BDTuringUtility.h"

@interface BDTuringServiceCenter ()

/// appid-serviceName => service
@property (nonatomic, strong) NSMutableDictionary<NSString * ,id<BDTuringService>> *services;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation BDTuringServiceCenter

- (instancetype)init {
    self = [super init];
    if (self) {
        self.services = [NSMutableDictionary new];
        self.semaphore = dispatch_semaphore_create(1);
    }

    return self;
}

+ (instancetype)defaultCenter {
    static BDTuringServiceCenter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (void)registerService:(id<BDTuringService>)service {
    NSString *serviceName = service.serviceName;
    NSString *appID = service.appID;
    if (!BDTuring_isValidString(appID)
        || !BDTuring_isValidString(serviceName)) {
        return;
    }
    dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));
    NSString *key = [NSString stringWithFormat:@"%@-%@", appID, serviceName];
    NSCAssert([self.services objectForKey:key] == nil, @"you will override a former registered service");
    [self.services setValue:service forKey:key];
    dispatch_semaphore_signal(self.semaphore);
}

- (void)unregisterService:(id<BDTuringService>)service {
    NSString *serviceName = service.serviceName;
    NSString *appID = service.appID;
    if (!BDTuring_isValidString(appID)
        || !BDTuring_isValidString(serviceName)) {
        return;
    }
    dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));
    NSString *key = [NSString stringWithFormat:@"%@-%@", appID, serviceName];
    [self.services removeObjectForKey:key];
    dispatch_semaphore_signal(self.semaphore);
}

- (id<BDTuringService>)serviceForName:(NSString *)serviceName appID:(NSString *)appID {
    if (!BDTuring_isValidString(appID)
        || !BDTuring_isValidString(serviceName)) {
        return nil;
    }
    id<BDTuringService> service = nil;
    dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));
    NSString *key = [NSString stringWithFormat:@"%@-%@",appID, serviceName];
    service = [self.services objectForKey:key];
    dispatch_semaphore_signal(self.semaphore);

    return service;
}

- (void)unregisterAllServices {
    dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));
    self.services = [NSMutableDictionary new];
    dispatch_semaphore_signal(self.semaphore);
}

- (void)popVerifyViewWithModel:(BDTuringVerifyModel *)model {
    NSString *serviceName = model.handlerName;
    NSString *appID = model.appID;
    if (!BDTuring_isValidString(appID)
        || !BDTuring_isValidString(serviceName)) {
        [model handleResultStatus:BDTuringVerifyStatusNotSupport];
        return;
    }
    
    id<BDTuringVerifyService> service = [self serviceForName:serviceName appID:appID];
    if (![service respondsToSelector:@selector(popVerifyViewWithModel:)]) {
        [model handleResultStatus:BDTuringVerifyStatusNotSupport];
        return;
    }
    
    [service popVerifyViewWithModel:model];
}

@end
