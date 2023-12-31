//
//  IESGurdSettingsCacheManager.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/21.
//

#import "IESGurdSettingsCacheManager.h"

#import "IESGeckoKit+Private.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdFilePaths.h"
#import "NSData+IESGurdKit.h"

static NSString * const kIESGurdKitAppVersion = @"kIESGurdKitAppVersion";

@interface IESGurdSettingsCacheManager ()

@property (nonatomic, copy) NSDictionary *settingsResponseDictionary;

@end

@implementation IESGurdSettingsCacheManager

#pragma mark - Public

+ (instancetype)sharedManager
{
    static IESGurdSettingsCacheManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (IESGurdSettingsResponse *)cachedSettingsResponse
{
    if (![IESGurdKit didSetup]) {
        return nil;
    }
    
    // 版本校验
    NSString *currentAppVersion = IESGurdKitInstance.appVersion;
    NSString *previousAppVersion = [[NSUserDefaults standardUserDefaults] objectForKey:kIESGurdKitAppVersion];
    [[NSUserDefaults standardUserDefaults] setObject:currentAppVersion forKey:kIESGurdKitAppVersion];
    if (previousAppVersion.length && ![previousAppVersion isEqualToString:currentAppVersion]) {
        [self removeLocalFiles];
        return nil;
    }
    
    // 二进制数据
    NSData *responseData = [self settingsDataWithPath:IESGurdFilePaths.settingsResponsePath];
    if (responseData.length == 0) {
        return nil;
    }
    // crc32 校验码
    NSData *responseCrc32Data = [self settingsDataWithPath:IESGurdFilePaths.settingsResponseCrc32Path];
    if (responseCrc32Data.length == 0) {
        return nil;
    }
    
    uint32_t responseCrc32;
    [responseCrc32Data getBytes:&responseCrc32 length:sizeof(responseCrc32)];
    // 校验二进制数据
    if ([responseData iesgurdkit_crc32] != responseCrc32) {
        [self removeLocalFiles];
        return nil;
    }
    
    NSDictionary *settingsResponseDictionary = [NSJSONSerialization JSONObjectWithData:responseData
                                                                               options:0
                                                                                 error:NULL];
    if (![settingsResponseDictionary[IESGurdSettingsAppVersionKey] isEqualToString:IESGurdKitInstance.appVersion]) {
        [self removeLocalFiles];
        return nil;
    }
    
    self.settingsResponseDictionary = settingsResponseDictionary;
    
    return [IESGurdSettingsResponse responseWithDictionary:settingsResponseDictionary];
}

- (void)saveResponseDictionary:(NSDictionary *)responseDictionary
{
    if (![IESGurdKit didSetup]) {
        return;
    }
    
    if (![responseDictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }
    self.settingsResponseDictionary = responseDictionary;
    
    NSMutableDictionary *updatedDictionary = [responseDictionary mutableCopy];
    updatedDictionary[IESGurdSettingsAppVersionKey] = IESGurdKitInstance.appVersion;
    
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:[updatedDictionary copy] options:0 error:NULL];
    if (![responseData writeToFile:IESGurdFilePaths.settingsResponsePath atomically:YES]) {
        return;
    }
    
    uint32_t crc32 = [responseData iesgurdkit_crc32];
    NSData *crc32Data = [NSData dataWithBytes:&crc32 length:sizeof(crc32)];
    if (![crc32Data writeToFile:IESGurdFilePaths.settingsResponseCrc32Path atomically:YES]) {
        [[NSFileManager defaultManager] removeItemAtPath:IESGurdFilePaths.settingsResponsePath error:NULL];
    }
}

- (void)cleanCache
{
    [self saveResponseDictionary:@{}];
}

#pragma mark - Private

- (NSData *)settingsDataWithPath:(NSString *)path
{
    return [NSData dataWithContentsOfFile:path
                                  options:NSDataReadingMappedIfSafe
                                    error:NULL];
}

- (void)removeLocalFiles
{
    [[NSFileManager defaultManager] removeItemAtPath:IESGurdFilePaths.settingsResponsePath error:NULL];
    [[NSFileManager defaultManager] removeItemAtPath:IESGurdFilePaths.settingsResponseCrc32Path error:NULL];
}

@end
