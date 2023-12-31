//
//  BDClientABStorageManager.m
//  ABTest
//
//  Created by ZhangLeonardo on 16/1/24.
//  Copyright © 2016年 ZhangLeonardo. All rights reserved.
//

#import "BDClientABStorageManager.h"
#import "BDClientABDefine.h"
#import "BDClientABManagerUtil.h"
#import "BDABKeychainStorage.h"

@interface BDClientABStorageManager()

@property (nonatomic, strong) BDABKeychainStorage *keychainManager;
@property (nonatomic, copy) NSDictionary *featureDicts;
@property (nonatomic, copy) NSDictionary *serverSettingFeatureDicts;
@property (nonatomic, copy) NSDictionary *layer2GroupMap;

@end

@implementation BDClientABStorageManager

- (id)init
{
    self = [super init];
    if (self) {
        self.keychainManager = [[BDABKeychainStorage alloc] initWithServiceName:@"ByteDanceClientABTestKeychain" useUserDefaultCache:YES];
        self.featureDicts = [self featureKeyDicts];
        self.serverSettingFeatureDicts = [self readServerSettingFeatureKeyDicts];
        [[self class] saveAPPVersionInfosIfNeed];
    }
    return self;
}

#pragma mark -- Feature Key
#pragma mark -- logic

- (id)valueForFeatureKey:(NSString *)key
{
    return [_featureDicts objectForKey:key];
}

- (id)serverSettingValueForFeatureKey:(NSString *)featureKey
{
    return [self.serverSettingFeatureDicts objectForKey:featureKey];
}

#pragma mark -- persistence store

#define kBDClientABStorageManagerFeatureUserDefaultKey @"kBDClientABStorageManagerFeatureUserDefaultKey"

- (void)resetFeatureKeys:(NSDictionary *)featureKeys
{
    _featureDicts = [NSDictionary dictionaryWithDictionary:featureKeys];
    if (![_featureDicts isKindOfClass:[NSDictionary class]] || [_featureDicts count] == 0) {
        return;
    }
    [self.keychainManager setObject:_featureDicts forKey:kBDClientABStorageManagerFeatureUserDefaultKey];
}

- (NSDictionary *)featureKeyDicts
{
    NSDictionary * result = [self.keychainManager objectForKey:kBDClientABStorageManagerFeatureUserDefaultKey];
    if ([result isKindOfClass:[NSDictionary class]]) {
        return result;
    }
    return nil;
}

#define kBDClientABStorageManagerServerSettingFeatureUserDefaultKey @"kBDClientABStorageManagerServerSettingFeatureUserDefaultKey"

- (void)resetServerSettingFeatureKeys:(NSDictionary *)featureKeys
{
    if (![featureKeys isKindOfClass:[NSDictionary class]] || [featureKeys count] == 0) {
        return;
    }
    //实验结果被服务端setting修改了，与服务端确认过不再上报，因此不需要同步更新当前命中分组
    [self.keychainManager setObject:featureKeys forKey:kBDClientABStorageManagerServerSettingFeatureUserDefaultKey];
    self.serverSettingFeatureDicts = featureKeys;
}

- (NSDictionary *)readServerSettingFeatureKeyDicts
{
    NSDictionary * result = [self.keychainManager objectForKey:kBDClientABStorageManagerServerSettingFeatureUserDefaultKey];
    if ([result isKindOfClass:[NSDictionary class]]) {
        return result;
    }
    return nil;
}

#pragma mark -- ABGroups

#define kBDClientABTestSavedLayer2GroupMapKey @"kBDClientABTestSavedLayer2GroupMapKey"

- (NSDictionary *)currentLayer2GroupMap
{
    if (![self.layer2GroupMap isKindOfClass:[NSDictionary class]]) {
        self.layer2GroupMap = nil;
        NSDictionary * map = [self.keychainManager objectForKey:kBDClientABTestSavedLayer2GroupMapKey];
        if ([map isKindOfClass:[NSDictionary class]]) {
            self.layer2GroupMap = map;
        }
    }
    return self.layer2GroupMap;
}

- (void)saveCurrentVersionLayer2GroupMap:(NSDictionary *)map
{
    if (![map isKindOfClass:[NSDictionary class]] || [map count] == 0) {
        self.layer2GroupMap = nil;
    } else {
        self.layer2GroupMap = map;
    }
    [self.keychainManager setObject:self.layer2GroupMap forKey:kBDClientABTestSavedLayer2GroupMapKey];
}

- (NSArray *)vidList
{
    return [[self currentLayer2GroupMap] allValues];
}

#pragma mark -- Random Number

#define kBDClientABTestRandomNumbersKey @"kBDClientABTestRandomNumbersKey"

- (NSDictionary *)randomNumber
{
    NSDictionary * dict = [self.keychainManager objectForKey:kBDClientABTestRandomNumbersKey];
    if ([dict isKindOfClass:[NSDictionary class]]) {
        return dict;
    }
    return nil;
}

- (void)saveRandomNumberDicts:(NSDictionary *)dict
{
    if (![dict isKindOfClass:[NSDictionary class]] || [dict count] == 0) {
        [self.keychainManager setObject:nil forKey:kBDClientABTestRandomNumbersKey];
    } else {
        [self.keychainManager setObject:dict forKey:kBDClientABTestRandomNumbersKey];
    }
}

#pragma mark -- AppVersion

#define kBDClientABManagerAppVersionUserDefaultKey @"kBDClientABManagerAppVersionUserDefaultKey"

- (void)saveAppVersion:(NSString *)AppVersion
{
    if (isEmptyString_forABManager(AppVersion)) {
        return;
    }
    [self.keychainManager setObject:@{@"AppVersion":AppVersion} forKey:kBDClientABManagerAppVersionUserDefaultKey];
}

- (NSString *)AppVersion
{
    NSString * result = nil;
    NSDictionary *temp = [self.keychainManager objectForKey:kBDClientABManagerAppVersionUserDefaultKey];
    if ([temp isKindOfClass:[NSDictionary class]]) {
        result = [temp objectForKey:@"AppVersion"];
    }
    if (isEmptyString_forABManager(result)) {
        return nil;
    }
    return result;
}

#pragma mark -- first install version

#define kBDClientABManagerFirstInstallVersionUDKey @"kBDClientABManagerFirstInstallVersionUDKey"

+ (void)saveAPPVersionInfosIfNeed
{
    NSString * firstInstallVersion = [self firstInstallVersionStr];
    if (isEmptyString_forABManager(firstInstallVersion)) {
        NSString * appVersion = [BDClientABManagerUtil appVersion];
        if (!isEmptyString_forABManager(appVersion)) {
            [[NSUserDefaults standardUserDefaults] setValue:appVersion forKey:kBDClientABManagerFirstInstallVersionUDKey];
        }
    }
}

+ (NSString *)firstInstallVersionStr
{
    NSString * version = [[NSUserDefaults standardUserDefaults] objectForKey:kBDClientABManagerFirstInstallVersionUDKey];
    if (isEmptyString_forABManager(version)) {
        return nil;
    }
    return version;
}

#pragma mark -- ABVersion

#define kBDClientABManagerABVersionUserDefaultKey @"kBDClientABManagerABVersionUserDefaultKey"

- (void)saveABVersion:(NSString *)ABVersion
{
    if (isEmptyString_forABManager(ABVersion)) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setValue:ABVersion forKey:kBDClientABManagerABVersionUserDefaultKey];
}

- (NSString *)ABVersion
{
    NSString * result = [[NSUserDefaults standardUserDefaults] objectForKey:kBDClientABManagerABVersionUserDefaultKey];
    if (isEmptyString_forABManager(result)) {
        return nil;
    }
    return result;
}

#pragma mark -- ABGroup

#define kBDClientABManagerABGroupUserDefaultKey @"kBDClientABManagerABGroupUserDefaultKey"

- (NSString *)ABGroup
{
    NSString * result = [[NSUserDefaults standardUserDefaults] objectForKey:kBDClientABManagerABGroupUserDefaultKey];
    if (isEmptyString_forABManager(result)) {
        return nil;
    }
    return result;
}

- (void)saveABGroup:(NSString *)ABGroup
{
    if (isEmptyString_forABManager(ABGroup)) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setValue:ABGroup forKey:kBDClientABManagerABGroupUserDefaultKey];
}

@end
