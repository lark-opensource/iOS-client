//
//  NSDictionary+IESGurdInternalPackage.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/9/22.
//

#import "NSDictionary+IESGurdInternalPackage.h"

#import "IESGurdFilePaths+InternalPackage.h"
#import "IESGeckoDefines+Private.h"

#import <pthread/pthread.h>

NSString * const kIESGurdInternalPackageConfigKeyAccessKey = @"access_key";
NSString * const kIESGurdInternalPackageConfigKeyChannel = @"channel";

@implementation NSDictionary (IESGurdInternalPackage)

static pthread_mutex_t kConfigLock = PTHREAD_MUTEX_INITIALIZER;

+ (NSDictionary *)gurd_configDictionaryWithBundleName:(NSString *)bundleName
{
    NSString *bundleKey = bundleName;
    if (bundleKey.length == 0) {
        bundleKey = @"IESGurdMainBundle";
    }
    
    GURD_MUTEX_LOCK(kConfigLock);
    
    static NSMutableDictionary<NSString *, NSDictionary *> *kConfigDictionaryCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kConfigDictionaryCache = [NSMutableDictionary dictionary];
    });
    
    NSDictionary *configDictionary = kConfigDictionaryCache[bundleKey];
    if (configDictionary) {
        return configDictionary;
    }
    
    NSString *configFilePath = [IESGurdFilePaths configFilePathWithBundleName:bundleName];
    NSData *configData = [NSData dataWithContentsOfFile:configFilePath];
    if (configData.length > 0) {
        NSError *jsonError = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:configData
                                                                   options:0
                                                                     error:&jsonError];
        if ([dictionary isKindOfClass:[NSDictionary class]]) {
            configDictionary = dictionary;
        }
    }
    
    if (!configDictionary) {
        configDictionary = @{};
    }
    kConfigDictionaryCache[bundleKey] = configDictionary;
    
    return configDictionary;
}

@end
