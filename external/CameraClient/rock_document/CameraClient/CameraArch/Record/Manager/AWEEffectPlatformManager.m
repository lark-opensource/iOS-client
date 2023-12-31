
//
//  AWEEffectPlatformManager.m
//  AWEFoundation
//
// Created by Hao Yipeng on April 25, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import "AWEEffectPlatformManager.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <EffectSDK_iOS/bef_effect_api.h>

#import <CreationKitArch/AWEEffectPlatformRequestManager.h>
#import <EffectPlatformSDK/IESFileDownloader.h>
#import <TTVideoEditor/IESMMTrackerManager.h>

#define EffectSDKEnable 1
#import <TTVideoEditor/IESMMParamModule.h>
#import <CreativeKit/ACCAPMProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <SSZipArchive/SSZipArchive.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <TTVideoEditor/IESMMTrackerManager.h>
#import <CreationKitArch/AWEStudioMeasureManager.h>
#import <CreativeKit/ACCENVProtocol.h>
#import <FileMD5Hash/FileHash.h>
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreationKitInfra/ACCDeviceInfo.h>
#import <HTSServiceKit/HTSMessageCenter.h>
#import <CreationKitInfra/ACCLangRegionLisener.h>
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>

/// User Service
#import <CreationKitArch/ACCModuleConfigProtocol.h>
#import <CreationKitInfra/ACCI18NConfigProtocol.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreationKitInfra/ACCCommonDefine.h>
#import <CreationKitArch/CKConfigKeysDefines.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogHelper.h>

#import "ACCConfigKeyDefines.h"

@interface AWEEffectPlatformManager () <ACCUserServiceMessage>

@property (nonatomic, strong) id<ACCModuleConfigProtocol> moduleConfig;
@property (nonatomic, strong) NSMutableDictionary *downloadingEffectMap;
@property (nonatomic, strong) dispatch_semaphore_t simpleDownloadingEffectsDictLock;

@end

@implementation AWEEffectPlatformManager
IESAutoInject(ACCBaseServiceProvider(), moduleConfig, ACCModuleConfigProtocol)

+ (instancetype)sharedManager
{
    static AWEEffectPlatformManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[AWEEffectPlatformManager alloc] init];
    });
    
    return _sharedManager;
}

+ (void)configEffectPlatform
{
    [self sharedManager];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_configEffectPlatformInner];
        _simpleDownloadingEffectsDictLock = dispatch_semaphore_create(1);
        // Observe the logout or switch user account message.
        REGISTER_MESSAGE(ACCUserServiceMessage, self);
        
#if INHOUSE_TARGET
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appRegionDidChange) name:ACC_REGION_CHANGE_NOTIFICATION object:nil];
#endif
    }
    return self;
}

- (void)dealloc
{
    UNREGISTER_MESSAGE(ACCUserServiceMessage, self);
#if INHOUSE_TARGET
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
}

- (void)p_configEffectPlatformInner
{
    NSString *region = [ACCI18NConfig() currentRegion];
#if INHOUSE_TARGET
        if (ACCConfigBool(kConfigBool_use_effect_cam_key)) {
            region = nil;
        }
#endif
    [self configEffectPlatform:[self.moduleConfig effectPlatformAccessKey] region:region];
}

- (void)configEffectPlatform:(NSString *)accessKey region:(NSString *)region
{
    [EffectPlatform startWithAccessKey:accessKey];
    [EffectPlatform setRegion:region];
    [EffectPlatform setAppId:[ACCDeviceInfo acc_appID]];
    [EffectPlatform setOsVersion:[ACCDeviceInfo acc_OSVersion]];
    
    // Platform optimization strategy represents the optimization strategy of special effects platform
    // https:// data.bytedance.net/libra/flight/341459/edit/
    NSNumber *platformOptimizeStrategy = @(ACCConfigInt(kConfigInt_platform_optimize_strategy));
    BOOL enableReducedEffectList = [platformOptimizeStrategy integerValue] == 2;
    [EffectPlatform setPlatformOptimizeStrategy:platformOptimizeStrategy];
    [EffectPlatform setEnableReducedEffectList:enableReducedEffectList];
    [EffectPlatform setDomain:self.moduleConfig.effectRequestDomainString];

    [EffectPlatform setChannel:[ACCDeviceInfo acc_currentChannel]];
    [EffectPlatform setDeviceIdentifier:[ACCTracker() deviceID]];
    [EffectPlatform setNetworkParametersBlock:^NSDictionary *{
        NSMutableDictionary *parameters = [ACCNetService() commonParameters].mutableCopy;
        
        if (!parameters[@"language"]) {
            NSString *languageCode = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
            NSString *scriptCode = [[NSLocale currentLocale] objectForKey:NSLocaleScriptCode];
            if (languageCode) {
                if (scriptCode) {
                    languageCode = [NSString stringWithFormat:@"%@-%@", languageCode, scriptCode];
                }
                [parameters setValue:languageCode forKey:@"language"];
            }
        }
        
        if (!parameters[@"app_language"]) {
            NSString *localelanguageCode = [ACCI18NConfig() currentLanguage];
            if (localelanguageCode) {
                [parameters setValue:localelanguageCode forKey:@"app_language"];
            }
        }
        
        if (ACCConfigBool(kConfigBool_use_online_effect_channel)) {
            parameters[@"channel"] = ACCConfigString(kConfigString_effect_platform_channel);
        }
        
        return parameters;
    }];
    
    NSDictionary *(^iopParamsBlock)(void) = self.moduleConfig.effectPlatformIOPParametersBlock;
    if (iopParamsBlock != nil) {
        [[EffectPlatform sharedInstance] setIopParametersBlock:iopParamsBlock];
    }

    if ([[IESMMTrackerManager shareInstance] respondsToSelector:@selector(postTracker:value:status:)]) {
        id<EffectPlatformTrackingDelegate> trackingDelegate =(id<EffectPlatformTrackingDelegate>)[IESMMTrackerManager shareInstance];
        [EffectPlatform setTrackingDelegate:trackingDelegate];
    }
    [[IESFileDownloader sharedInstance] setMaxConcurrentCount:4];
    
    
    char version[10] = {0};
    char commit[12] = {0};
#if !TARGET_IPHONE_SIMULATOR
    bef_effect_get_sdk_version(version,sizeof(version));
    bef_effect_get_sdk_commit(commit, sizeof(commit));
#endif
    NSString *versionString = [[NSString alloc] initWithUTF8String:version];
    NSString *commitString = [[NSString alloc] initWithUTF8String:commit];
    
    if (versionString.length > 0) {
        [EffectPlatform setEffectSDKVersion:versionString];
        [ACCAPM() attachInfo:versionString forKey:@"effect_sdk_version"];
    } else {
        [EffectPlatform setEffectSDKVersion:@"2.8.0"];
    }
    
    if (commitString.length > 0) {
        [ACCAPM() attachInfo:commitString forKey:@"effect_sdk_commit"];
    }
    
    NSString *videoEditorVersion = [IESMMTrackerManager getEditorVersion];
    if (videoEditorVersion.length) {
        [ACCAPM() attachInfo:videoEditorVersion forKey:@"ve_sdk_version"];
    }
    
    [self setUpEffectManager];
    
    // When new effect manager (refactor) is enabled. Clean the old directory to save disk space.
    // Clean up the special effects and algorithm model under the old directory to save disk space
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [EffectPlatform clearEffectsAndAlgorithms];
    });
}

- (void)setUpEffectManager {
    NSString *domain = self.moduleConfig.effectRequestDomainString;
    [IESEffectManager manager].config.deviceIdentifier = [ACCTracker() deviceID];
    [IESEffectManager manager].config.appID = [ACCDeviceInfo acc_appID]; // 1128
    [IESEffectManager manager].config.region = [ACCI18NConfig() currentRegion];
    [IESEffectManager manager].config.domain = domain;
    [IESEffectManager manager].config.enableAutoCleanCache = YES;
#if INHOUSE_TARGET
    [IESEffectManager manager].config.downloadOnlineEnviromentModel = ACCConfigBool(kConfigBool_use_online_algrithm_model_environment);
#endif

    [IESMMParamModule setResourceFinder:[[IESEffectManager manager] getResourceFinder]];
    
    // 设置清理白名单，必须要在`setUp`之前调用，否则 AutoClean 会将忽略掉白名单
    let effectplatCleanAllowList = ACCConfigArray(kConfigArray_studio_effectplat_clean_allow_list);
    [[IESEffectManager manager] addAllowPanelListForEffectUnClean:effectplatCleanAllowList];
    
    [[IESEffectManager manager] setUp];
    
    self.effectListManager = [[IESEffectListManager alloc] initWithAccessKey:[self.moduleConfig effectPlatformAccessKey] config:[IESEffectManager manager].config];
    self.effectListManager.delegate = self;
    
    [IESEffectLogger logger].loggerProxy = self;
    [IESMMParamModule sharedInstance].resourceDownloader = ^(NSArray<NSString *> * _Nonnull requirements, NSDictionary<NSString *,NSArray<NSString *> *> * _Nonnull modelNames, veResourceDownloaderResult _Nonnull resultBlock) {
        // The internal part of the effect platform will determine whether the model has been downloaded
        [EffectPlatform fetchResourcesWithRequirements:requirements modelNames:modelNames completion:^(BOOL success, NSError * _Nonnull error) {
            ACCBLOCK_INVOKE(resultBlock, success, error);
        }];
    };
}

-(NSMutableDictionary *)downloadingEffectMap
{
    if (_downloadingEffectMap == nil) {
        _downloadingEffectMap = [NSMutableDictionary dictionary];
    }
    return _downloadingEffectMap;
}

#pragma mark - ACCRegionMessage

#if INHOUSE_TARGET
- (void)appRegionDidChange
{
    [self.moduleConfig effectDealWithRegionDidChange];
}
#endif

#pragma mark - IESEffectLoggerProtocol

- (void)log:(NSString *)log type:(IESEffectPlatformLogType)type {
    switch (type) {
        case IESEffectPlatformLogInfo:
            AWELogToolInfo(AWELogToolTagEffectPlatform, @"%@", log);
            break;
        case IESEffectPlatformLogWarn:
            AWELogToolWarn(AWELogToolTagEffectPlatform, @"%@", log);
            break;;
        case IESEffectPlatformLogDebug:
            AWELogToolDebug(AWELogToolTagEffectPlatform, @"%@", log);
            break;
        case IESEffectPlatformLogError:
            AWELogToolError(AWELogToolTagEffectPlatform, @"%@", log);
            break;
        default:
            NSAssert(NO, @"log type should implement!!!");
            break;
    }
}

- (void)logEvent:(NSString *)event params:(nullable NSDictionary *)params {
    if (event && event.length > 0) {
        [ACCTracker() trackEvent:event params:params?:@{} needStagingFlag:NO];
    }
}

- (void)trackService:(NSString *)serviceName status:(NSInteger)status extra:(NSDictionary *)extraValue {
    [[AWEStudioMeasureManager sharedMeasureManager] asyncMonitorTrackService:serviceName status:status extra:extraValue];
}

#pragma mark - IESEffectListManagerDelegate

- (void)effectListManager:(IESEffectListManager *)effectListManager
   willSendRequestWithURL:(nonnull NSString *)URL
               parameters:(nonnull NSMutableDictionary *)parameters {
    NSMutableDictionary *customParameters = [[NSMutableDictionary alloc] init];
    NSDictionary *commonParameters = [ACCNetService() commonParameters];
    if (commonParameters.count > 0) {
        [customParameters addEntriesFromDictionary:commonParameters];
    }

    if (!customParameters[@"language"]) {
        NSString *languageCode = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
        NSString *scriptCode = [[NSLocale currentLocale] objectForKey:NSLocaleScriptCode];
        if (languageCode) {
            if (scriptCode) {
                languageCode = [NSString stringWithFormat:@"%@-%@", languageCode, scriptCode];
            }
            [customParameters setValue:languageCode forKey:@"language"];
        }
    }
    
    if (!customParameters[@"app_language"]) {
        NSString *localelanguageCode = [ACCI18NConfig() currentLanguage];
        if (localelanguageCode) {
            [customParameters setValue:localelanguageCode forKey:@"app_language"];
        }
    }

    if (ACCConfigBool(kConfigBool_use_online_effect_channel)) {
        customParameters[@"channel"] = ACCConfigString(kConfigString_effect_platform_channel);
    } else {
        customParameters[@"channel"] = @"test";
        NSInteger statusCode = ACCConfigInt(kConfigInt_effect_test_status_code);
        customParameters[@"test_status"] = [NSString stringWithFormat:@"%ld", (long)statusCode];
    }
    
    NSDictionary *extraParameters = [self.moduleConfig effectPlatformExtraCustomParameters];
    if (extraParameters.count > 0) {
        [customParameters addEntriesFromDictionary:extraParameters];
    }
    
    // Add custom parameters
    [parameters addEntriesFromDictionary:customParameters];
}

#pragma mark - voice effect

- (NSString *)localVoiceEffectName_chipmunk
{
    return @"chipmunk";
}

- (NSString *)localVoiceEffectName_baritone
{
    return @"baritone";
}

- (NSArray <IESEffectModel *> *)localVoiceEffectList
{
    // cache
    NSBundle *studioBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"AWEStudio" ofType:@"bundle"]];
    BOOL localCache_chipmunk = NO;
    NSString *chipmunk_zipPath = [studioBundle pathForResource:self.localVoiceEffectName_chipmunk ofType:@"zip"];
    NSString *chipmunk_uncompressPath = IESEffectUncompressPathWithIdentifier(self.localVoiceEffectName_chipmunk);
    NSMutableString *chipmunk_localUnCompressPath = [NSMutableString stringWithString:chipmunk_uncompressPath];
    [chipmunk_localUnCompressPath appendString:@"/chipmunk"];
    if (chipmunk_zipPath && [[NSFileManager defaultManager] fileExistsAtPath:chipmunk_zipPath]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:chipmunk_uncompressPath]) {
            localCache_chipmunk = YES;
        }
    }
    
    BOOL localCache_baritone = NO;
    NSString *baritone_zipPath = [studioBundle pathForResource:self.localVoiceEffectName_baritone ofType:@"zip"];
    NSString *baritone_uncompressPath = IESEffectUncompressPathWithIdentifier(self.localVoiceEffectName_baritone);
    NSMutableString *baritone_localUnCompressPath = [NSMutableString stringWithString:baritone_uncompressPath];
    [baritone_localUnCompressPath appendString:@"/baritone"];
    if (baritone_zipPath && [[NSFileManager defaultManager] fileExistsAtPath:baritone_zipPath]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:baritone_uncompressPath]) {
            localCache_baritone = YES;
        }
    }
    
    if (localCache_chipmunk && localCache_baritone && [_localVoiceEffectList count]) {// has cache
        return _localVoiceEffectList;
    } else {// unzip
        NSMutableArray *arr = [NSMutableArray array];

        // chipmunk
        if (chipmunk_zipPath && [[NSFileManager defaultManager] fileExistsAtPath:chipmunk_zipPath]) {
            NSDictionary *json = @{@"name" : ACCLocalizedCurrentString(@"av_voice_chipmunk"), @"effect_id" : self.localVoiceEffectName_chipmunk};
            IESEffectModel *chipmunk = [MTLJSONAdapter modelOfClass:IESEffectModel.class fromJSONDictionary:json error:nil];
            if (![[NSFileManager defaultManager] fileExistsAtPath:chipmunk_uncompressPath]) {
                if ([SSZipArchive unzipFileAtPath:chipmunk_zipPath toDestination:chipmunk_uncompressPath]) {
                    if ([[NSFileManager defaultManager] fileExistsAtPath:chipmunk_uncompressPath]) {
                        // uncompress success
                        chipmunk.localUnCompressPath = chipmunk_localUnCompressPath;
                        chipmunk.localVoiceEffectTag = @"default_1";
                        [arr acc_addObject:chipmunk];
                    }
                }
            } else {// already uncompressed chipmunk
                chipmunk.localUnCompressPath = chipmunk_localUnCompressPath;
                chipmunk.localVoiceEffectTag = @"default_1";
                [arr acc_addObject:chipmunk];
            }
        }
        
        // baritone
        if (baritone_zipPath && [[NSFileManager defaultManager] fileExistsAtPath:baritone_zipPath]) {
            NSDictionary *json = @{@"name" : ACCLocalizedCurrentString(@"av_voice_baritone"), @"effect_id" : self.localVoiceEffectName_baritone};
            IESEffectModel *baritone = [MTLJSONAdapter modelOfClass:IESEffectModel.class fromJSONDictionary:json error:nil];
            if (![[NSFileManager defaultManager] fileExistsAtPath:baritone_uncompressPath]) {
                if ([SSZipArchive unzipFileAtPath:baritone_zipPath toDestination:baritone_uncompressPath]) {
                    if ([[NSFileManager defaultManager] fileExistsAtPath:baritone_uncompressPath]) {
                        // uncompress success
                        baritone.localUnCompressPath = baritone_localUnCompressPath;
                        baritone.localVoiceEffectTag = @"default_2";
                        [arr acc_addObject:baritone];
                    }
                }
            } else {// already uncompressed baritone
                baritone.localUnCompressPath = baritone_localUnCompressPath;
                baritone.localVoiceEffectTag = @"default_2";
                [arr acc_addObject:baritone];
            }
        }
        
        _localVoiceEffectList = [NSArray arrayWithArray:arr];
        return _localVoiceEffectList;
    }
}

- (IESEffectModel *)localVoiceEffectWithID:(NSString *)effectID
{
    __block IESEffectModel *effect = nil;
    if (effectID && [self.localVoiceEffectList count]) {
        [self.localVoiceEffectList enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.effectIdentifier isEqualToString:effectID]) {
                effect = obj;
                *stop = YES;
            }
        }];
    }
    return effect;
}

- (IESEffectModel *)cachedVoiceEffectWithID:(NSString *)effectID
{
    __block IESEffectModel *effect = nil;
    NSString *pannel = @"voicechanger";
    NSString *category = @"all";
    IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:pannel category:category];
    
    if (effectID && [cachedResponse.categoryEffects.effects count]) {
        [cachedResponse.categoryEffects.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.effectIdentifier isEqualToString:effectID]) {
                effect = obj;
                *stop = YES;
            }
        }];
    }
    
    return effect;
}

- (BOOL)equalWithCachedEffect:(IESEffectModel *)cached localEffect:(IESEffectModel *)local
{
    __block BOOL isEqual = NO;
    if ([cached.tags count]) {
        [cached.tags enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSString class]]) {
                if ([obj isEqualToString:local.localVoiceEffectTag]) {
                    isEqual = YES;
                    *stop = YES;
                }
            }
        }];
    }
    
    return isEqual;
}

// Read the cache first and download it if you don't have it. You should clear the cache
- (void)loadEffectWithID:(NSString *)effectId completion:(void (^)(IESEffectModel *))completion
{
    if (![effectId length]) {
        ACCBLOCK_INVOKE(completion, nil);
        return;
    }
    
    IESEffectModel *effect = [self cachedVoiceEffectWithID:effectId];
    if (!effect || !effect.downloaded) {
        [EffectPlatform downloadEffectListWithEffectIDS:@[effectId] completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects) {
            if (error || ![effects count]) {
                acc_dispatch_main_async_safe(^{
                    ACCBLOCK_INVOKE(completion, nil);
                });
            } else {
                IESEffectModel *validEffect = effects.firstObject;
                [EffectPlatform downloadEffect:validEffect progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                    acc_dispatch_main_async_safe(^{
                        if (error || ![effects count] || !validEffect.downloaded) {
                            ACCBLOCK_INVOKE(completion, nil);
                        } else {
                            ACCBLOCK_INVOKE(completion, validEffect);
                        }
                    });
                }];
            }
        }];
    } else {
        ACCBLOCK_INVOKE(completion, effect);
    }
}

- (AWEEffectDownloadStatus)downloadStatusForEffect:(IESEffectModel *)effect
{
    if (!effect.effectIdentifier.length ||
        effect.downloaded ||
        ([effect.effectIdentifier isEqualToString:[AWEEffectPlatformManager sharedManager].localVoiceEffectName_chipmunk] ||
        [effect.effectIdentifier isEqualToString:[AWEEffectPlatformManager sharedManager].localVoiceEffectName_baritone])) {
        return AWEEffectDownloadStatusDownloaded;
    }
    
    if (self.downloadingEffectMap[effect.effectIdentifier]) {
        return AWEEffectDownloadStatusDownloading;
    }
    return AWEEffectDownloadStatusUndownloaded;
}

- (void)downloadEffect:(IESEffectModel *)effect
              progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
            completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion
{
    self.downloadingEffectMap[effect.effectIdentifier] = effect;
    @weakify(self);
    [EffectPlatform downloadEffect:effect progress:progressBlock completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
        @strongify(self);
        self.downloadingEffectMap[effect.effectIdentifier] = nil;
        ACCBLOCK_INVOKE(completion, error, filePath);
    }];
}

#pragma mark - ACCUserServiceMessage

- (void)didFinishLogout {
    // Clear the effect list cache (only including effect list memory and disk cache, not include effect and algorithm model resource.) when
    // user logout or switch to another account.
    [[EffectPlatform sharedInstance].cache clear];
}

@end
