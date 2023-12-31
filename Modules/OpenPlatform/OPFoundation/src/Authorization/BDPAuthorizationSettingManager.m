//
//  BDPAuthorizationSettingManager.m
//  Timor
//
//  Created by liuxiangxin on 2019/6/27.
//

#import "BDPAuthorizationSettingManager.h"
#import "BDPSettingsManager+BDPExtension.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>

@interface BDPAuthorizationSettingManager ()

@property (nonatomic, copy) NSDictionary *config;
@property (nonatomic, strong) dispatch_semaphore_t internalLock;

@end

@implementation BDPAuthorizationSettingManager

#pragma mark - init

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static BDPAuthorizationSettingManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[BDPAuthorizationSettingManager alloc] initPrivate];
    });
    
    return manager;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        _internalLock = dispatch_semaphore_create(1);
    }
    return self;
}


- (BOOL)shouldUseCombineAuthorizeForUniqueID:(BDPUniqueID *)uniqueID
{
    if (!uniqueID.isValid) {
        return NO;
    }
    
    if (![BDPSettingsManager.sharedManager s_boolValueForKey:kBDPSABTestAuthorizeListOn]) {
        return YES;
    };
    
    NSArray<NSString *> *whiteList = [BDPSettingsManager.sharedManager s_arrayValueForKey:kBDPSABTestAuthorizeListMpid] ? : @[];
    
    BOOL contains = [whiteList containsObject:uniqueID.appID];

    return contains;
}

@end
