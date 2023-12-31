//
//  IESGurdRegisterManager.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/14.
//

#import "IESGurdRegisterManager.h"

#import "IESGeckoDefines.h"
#import "IESGeckoDefines+Private.h"

@interface IESGurdRegisterModel ()
@property (nonatomic, readwrite, copy) NSString *accessKey;
@property (nonatomic, readwrite, copy) NSString *version;
@end

@interface IESGurdRegisterManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, IESGurdRegisterModel *> *registerModelsDictionary;

@end

@implementation IESGurdRegisterManager

+ (instancetype)sharedManager
{
    static IESGurdRegisterManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.registerModelsDictionary = [NSMutableDictionary dictionary];
    });
    return manager;
}

#pragma mark - Public

- (void)registerAccessKey:(NSString *)accessKey
{
    [self registerAccessKey:accessKey SDKVersion:nil];
}

- (void)registerAccessKey:(NSString *)accessKey SDKVersion:(NSString * _Nullable)SDKVersion
{
    if (IES_isEmptyString(accessKey)) {
        return;
    }
    
    BOOL shouldNotifyNewAccessKey = NO;
    @synchronized (self.registerModelsDictionary) {
        IESGurdRegisterModel *registerModel = self.registerModelsDictionary[accessKey];
        if (!registerModel) {
            registerModel = [[IESGurdRegisterModel alloc] init];
            registerModel.isRegister = YES;
            registerModel.accessKey = accessKey;
            registerModel.version = SDKVersion;
            self.registerModelsDictionary[accessKey] = registerModel;
            
            shouldNotifyNewAccessKey = YES;
        } else if (!registerModel.isRegister) {
            // 有可能通过addCustomParamsForAccessKey已经生成registerModel，这里更新sdkversion
            registerModel.isRegister = YES;
            registerModel.version = SDKVersion;
            shouldNotifyNewAccessKey = YES;
        }
    }
    if (shouldNotifyNewAccessKey) {
        [[NSNotificationCenter defaultCenter] postNotificationName:IESGurdKitDidRegisterAccessKeyNotification
                                                            object:nil];
    }
}

- (void)addCustomParamsForAccessKey:(NSString *)accessKey
                       customParams:(NSDictionary * _Nullable)customParams
{
    if (IES_isEmptyString(accessKey)) {
        return;
    }
    
    @synchronized (self.registerModelsDictionary) {
        IESGurdRegisterModel *registerModel = self.registerModelsDictionary[accessKey];
        if (!registerModel) {
            registerModel = [[IESGurdRegisterModel alloc] init];
            registerModel.accessKey = accessKey;
            registerModel.customParams = customParams;
            self.registerModelsDictionary[accessKey] = registerModel;
        } else {
            if (registerModel.customParams) {
                NSMutableDictionary *newCustomParams = [registerModel.customParams mutableCopy];
                [newCustomParams addEntriesFromDictionary:customParams];
                registerModel.customParams = newCustomParams;
            } else {
                registerModel.customParams = customParams;
            }
        }
    }
}

- (BOOL)isAccessKeyRegistered:(NSString *)accessKey
{
    if (IES_isEmptyString(accessKey)) {
        return NO;
    }
    
    @synchronized (self.registerModelsDictionary) {
        return self.registerModelsDictionary[accessKey].isRegister;
    }
}

- (IESGurdRegisterModel *)registerModelWithAccessKey:(NSString *)accessKey
{
    if (IES_isEmptyString(accessKey)) {
        return nil;
    }
    
    @synchronized (self.registerModelsDictionary) {
        return self.registerModelsDictionary[accessKey];
    }
}

- (NSArray<NSString *> *)allAccessKeys
{
    @synchronized (self.registerModelsDictionary) {
        return [self.registerModelsDictionary allKeys];
    }
}

- (NSArray<IESGurdRegisterModel *> *)allRegisterModels
{
    @synchronized (self.registerModelsDictionary) {
        return [self.registerModelsDictionary allValues];
    }
}

@end
