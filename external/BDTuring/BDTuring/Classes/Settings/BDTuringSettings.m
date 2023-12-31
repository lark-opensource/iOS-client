//
//  BDTuringSettings.m
//  BDTuring
//
//  Created by bob on 2020/4/8.
//

#import "BDTuringSettings.h"
#import "BDTuringSettings+Default.h"
#import "BDTuringSettings+Report.h"
#import "BDTuringSettings+Custom.h"

#import "BDTuringServiceCenter.h"
#import "BDTuringConfig+Parameters.h"

#import "NSDictionary+BDTuring.h"
#import "BDTuringUtility.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringDefine.h"
#import "BDTNetworkManager.h"
#import "BDTuringMacro.h"
#import "NSData+BDTuring.h"

#import <BDDataDecorator/NSData+DecoratorAdditions.h>
#import <Godzippa/NSData+Godzippa.h>
#import "BDTuringEventService.h"

static NSString *const SettingsServiceName    = @"SettingsServiceName";
static NSString *const kBDTuringConfigLastSuccessTime = @"kBDTuringConfigLastSuccessTime";
static NSString *const kBDTuringConfigRegion = @"kBDTuringConfigRegion";

@interface BDTuringSettings ()

@property (nonatomic, strong) NSMutableDictionary *settings;
@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, assign) long long period; /// millisecond
@property (nonatomic, assign) long long lastSuccessTime;
@property (nonatomic, assign) long long retryInterval;
@property (nonatomic, assign) long long retryCount;
@property (nonatomic, assign) BOOL preCreate;
@property (nonatomic, assign) BOOL isUpdatingSettings;
@property (nonatomic, strong) BDTuringConfig *config;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *iv;
@property (nonatomic, copy) NSString *lastRegion;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) dispatch_block_t completion;

@end

@implementation BDTuringSettings

+ (instancetype)settingsForAppID:(NSString *)appID {
    if (appID.length < 1) {
        return nil;
    }
    
    BDTuringSettings *service = [[BDTuringServiceCenter defaultCenter] serviceForName:SettingsServiceName appID:appID];
    if ([service isKindOfClass:[BDTuringSettings class]]) {
        return service;
    }
    
    service = [[BDTuringSettings alloc] initWithAppID:appID];
    [service registerService];
    
    return service;
}


+ (instancetype)settingsForConfig:(BDTuringConfig *)config {
    BDTuringSettings *service = [self settingsForAppID:config.appID];
    service.config = config;
    
    return service;
}

- (void)dealloc {
    
}

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID];
    if (self) {
        NSString *path = [turing_sdkDocumentPathForAppID(appID) stringByAppendingPathComponent:@"config_v2.plist"];
        self.filePath = path;
        NSString *queueName = [NSString stringWithFormat:@"com.bytedance.turing.sdk_%@", appID];
        self.serialQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
        self.isUpdatingSettings = NO;
        self.key = [[NSUUID UUID].UUIDString substringToIndex:32];
        self.iv = [[NSUUID UUID].UUIDString substringToIndex:16];
        self.completion = nil;
        [self loadLocalSettings];
    }

    return self;
}

- (void)loadLocalSettings {
    dispatch_sync(self.serialQueue, ^{
        NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:self.filePath] ?: [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityMid];
        
        self.lastSuccessTime = [settings turing_longLongValueForKey:kBDTuringConfigLastSuccessTime defaultValue:0];
        self.lastRegion = [settings turing_stringValueForKey:kBDTuringConfigRegion];
        self.settings = settings;
        [self reloadDefaultSettings];
        [self reloadCustomSettings];
        [self readCommonSettings];
    });
}

- (void)readCommonSettings {
    NSMutableDictionary *settings = self.settings;
    NSDictionary *common = [settings turing_dictionaryValueForKey:kBDTuringSettingsPluginCommon];
    
    long long period = [common turing_longLongValueForKey:kBDTuringSettingsPeriod defaultValue:3600 * 1000];
    /// min= 5 minutes
    self.period = MAX(period, 5 * 60 * 1000);
    self.retryInterval = [common turing_longLongValueForKey:kBDTuringSettingsRetryInterval defaultValue:2000];
    self.retryCount = [common turing_longLongValueForKey:kBDTuringSettingsRetryCount defaultValue:3];
    self.preCreate = [common turing_boolValueForKey:kBDTuringSettingsPreCreate];
}

- (NSString *)serviceName {
    return SettingsServiceName;
}

- (BOOL)serviceAvailable {
    return self.settings.count > 3;
}

- (BOOL)sholdRequest {
    /// refetch when region changed
    NSString *region = turing_regionFromRegionType(self.config.regionType);
    if (!BDTuring_isValidString(region)) {
        return NO;
    }
    
    if (![self.lastRegion isEqualToString:region]) {
        return YES;
    }
    
    if (!self.serviceAvailable) {
        return YES;
    }
    
    long long duration = turing_duration_ms(self.lastSuccessTime);
    if (duration >= self.period) {
        return YES;
    }
    
    return NO;
}

- (BOOL)handleResponseData:(NSData *)data region:(NSString *)region {
    NSData *decryptData = [data bdd_aesDecryptwithKey:self.key
                                              keySize:(BDDecoratorKeySizeAES256)
                                                   iv:self.iv];
    if ([decryptData turing_isGzipCompressed]) {
        decryptData = [decryptData dataByGZipDecompressingDataWithError:nil];
    }
    NSMutableDictionary *settings = [decryptData turing_mutableDictionaryFromJSONData];
    
    if (settings == nil) {
        settings = [data turing_mutableDictionaryFromJSONData];
    }
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"BDTuringSettings"
//                                                            object:nil
//                                                          userInfo:settings];
//    });
    /// must have to keys
    if (![settings isKindOfClass:[NSMutableDictionary class]] || settings.count < 2) {
        return NO;
    }
    self.lastRegion = region;
    long long last = turing_duration_ms(0);
    [settings setValue:@(last) forKey:kBDTuringConfigLastSuccessTime];
    [settings setValue:region forKey:kBDTuringConfigRegion];
    self.lastSuccessTime = last;
    [self reportRequestResult:0];
    if (@available(iOS 11, *)) {
        [settings writeToURL:[NSURL fileURLWithPath:self.filePath] error:nil];
    } else {
        [settings writeToFile:self.filePath atomically:YES];
    }
    
    self.settings = [settings mutableCopy];
    [self reloadDefaultSettings];
    [self reloadCustomSettings];
    [self readCommonSettings];
    return YES;
}

- (void)fetchSettingsWithRetry:(NSInteger)retry useBackup:(BOOL)useBackup {
    if (retry < 0) {
        [self handleCompletion];
        return;
    }
    
    self.isUpdatingSettings = YES;
    self.startRequestTime = turing_duration_ms(0);
    NSString *region = turing_regionFromRegionType(self.config.regionType);
    NSString *type = useBackup ? kBDTuringSettingsBackupHost : kBDTuringSettingsHost;
    NSString *reuqestURL = [self requestURLForPlugin:kBDTuringSettingsPluginCommon
                                             URLType:type
                                              region:region];
    
    if (reuqestURL.length < 1) {
        [self handleCompletion];
        return;
    }
    
    reuqestURL = turing_requestURLWithPath(reuqestURL,@"vc/setting");
    NSMutableDictionary *post = [self.config requestPostParameters];
    [post setValue:self.key forKey:@"key"];
    [post setValue:self.iv forKey:@"iv"];
    
    BDTuringWeakSelf;
    BDTuringNetworkFinishBlock callback = ^(NSData *data) {
        BDTuringStrongSelf;
        BOOL result = [self handleResponseData:data region:region];
        [self handleCompletion];
        if (result) {
            return;
        }
        
        [self reportRequestResult:useBackup ? 2 : 1];
        if (retry > 0) {
            self.isUpdatingSettings = YES;
            NSInteger next = retry - 1;
            BOOL tryBackup = next <= self.retryCount;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryInterval * NSEC_PER_MSEC)), self.serialQueue, ^{
                BDTuringStrongSelf;
                [self fetchSettingsWithRetry:next useBackup:tryBackup];
            });
        }
        
    };
    
    [BDTNetworkManager asyncRequestForURL:reuqestURL
                                   method:@"POST"
                          queryParameters:[self.config requestQueryParameters]
                           postParameters:post
                                 callback:callback
                            callbackQueue:self.serialQueue
                                  encrypt:YES
                                  tagType:BDTNetworkTagTypeAuto];
    
}

- (void)handleCompletion {
    self.isUpdatingSettings = NO;
    dispatch_block_t completion = self.completion;
    if (completion) {
        self.completion = nil;
        dispatch_async(dispatch_get_main_queue(), completion);
    }
}

- (void)checkAndFetchSettingsWithCompletion:(dispatch_block_t)completion {
    dispatch_async(self.serialQueue, ^{
        if (![self sholdRequest]) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), completion);
            }
            return;
        }
        if (completion) {
            self.completion = completion;
        }
        if (self.isUpdatingSettings) {
            return;
        }
        
        [self fetchSettingsWithRetry:self.retryCount * 2 useBackup:NO];
    });
}

- (NSString *)requestURLForPlugin:(NSString *)plugin
                          URLType:(NSString *)URLType
                           region:(NSString *)region {
    NSDictionary *pluginDict = [self.settings turing_dictionaryValueForKey:plugin];
    NSDictionary *URLDict = [pluginDict turing_dictionaryValueForKey:URLType];
    NSString *requestURL = [URLDict turing_stringValueForKey:region];
    
    return requestURL;
}

- (id)settingsForPlugin:(NSString *)plugin
                    key:(NSString *)key
           defaultValue:(id)defaultValue {
    if (key == nil) {
        return defaultValue;
    }
    
    NSDictionary *pluginDict = [self.settings turing_dictionaryValueForKey:plugin];
    
    return [pluginDict objectForKey:key] ?: defaultValue;
}

- (void)addPlugin:(NSString *)plugin
             key1:(NSString *)key1
           region:(NSString *)region
            value:(id)value {
    [self addPlugin:plugin key1:key1 region:region value:value forceUpdate:NO];
}

- (void)addPlugin:(NSString *)plugin
             key1:(NSString *)key1
           region:(NSString *)region
            value:(id)value
      forceUpdate:(BOOL)forceUpdate {
    if (key1 == nil || plugin == nil) {
        return;
    }
    
    NSMutableDictionary *pluginDict = [self.settings turing_mutableDictionaryValueForKey:plugin];
    if (pluginDict == nil) {
        pluginDict = [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityMid];
        [self.settings setValue:pluginDict forKey:plugin];
    }
    if (!BDTuring_isValidString(region)) {
        NSString *oldValue = [pluginDict turing_stringValueForKey:key1];
        if (forceUpdate || !BDTuring_isValidString(oldValue)) {
            [pluginDict setValue:value forKey:key1];
        }
    } else {
        NSMutableDictionary *nextDict = [pluginDict turing_mutableDictionaryValueForKey:key1];
        if (nextDict == nil) {
            nextDict = [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityMid];
            [pluginDict setValue:nextDict forKey:key1];
        }
        NSString *oldValue = [nextDict turing_stringValueForKey:region];
        if (forceUpdate || !BDTuring_isValidString(oldValue)) {
            [nextDict setValue:value forKey:region];
        }
    }
}

- (void)cleanSettings {
    dispatch_sync(self.serialQueue, ^{
        [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
        self.settings = [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityMid];
        self.lastSuccessTime = 0;
        [self reloadDefaultSettings];
        [self reloadCustomSettings];
        [self readCommonSettings];
        [self checkAndFetchSettingsWithCompletion:nil];
    });
}

@end
