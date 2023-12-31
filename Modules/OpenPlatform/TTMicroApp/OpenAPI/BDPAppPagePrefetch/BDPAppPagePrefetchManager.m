//
//  BDPAppPagePrefetchManager.m
//  Timor
//
//  Created by 李靖宇 on 2019/11/25.
//

#import <ECOInfra/BDPUtils.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/EEFeatureGating.h>
#import <OPFoundation/BDPSchemaCodec+Private.h>

#import <OPFoundation/BDPSchema.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPSchemaCodec.h>
#import <OPFoundation/BDPMacroUtils.h>
//#import "BDPMessageCenter.h"
//#import "BDPWarmBootMessage.h"
#import "BDPLocalFileManager.h"
#import "BDPAppPagePrefetcher.h"
#import "BDPAppPagePrefetchManager.h"

#import <OPFoundation/BDPSettingsManager+BDPExtension.h>

#import <ECOInfra/ECOInfra-Swift.h>
//#import <ByteDanceKit/NSData+BTDAdditions.h>
//#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

#define PrefetchFileName @"prefetches"
// 版本标识
#define PrefetchVersionKey @"pfVer"
// 预拉取接口列表
#define PrefetchListKey @"pfList"
// 预拉取接口命中规则列表
#define PrefetchHitRulesListKey @"pfHitRulesList"
// 预拉取备用页面Path
#define PrefetchBackUpPathKey @"pfBackUpPath"
#import <TTMicroApp/TTMicroApp-Swift.h>

//@interface BDPAppPagePrefetchManager ()<BDPWarmBootMessage>
@interface BDPAppPagePrefetchManager ()

@property (nonatomic,strong, direct) NSCache<NSString *,BDPAppPagePrefetcher *> *prefetcherDic;
@property (nonatomic,strong) dispatch_semaphore_t semaphore;

@end

@implementation BDPAppPagePrefetchManager

+ (instancetype)sharedManager {
    if (![PrefetchLarkFeatureGatingDependcy prefetchEnable]) {
        return nil;
    }
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDPAppPagePrefetchManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.prefetcherDic = [[NSCache alloc] init];
        self.prefetcherDic.countLimit = 6;
        self.semaphore = dispatch_semaphore_create(1);
//        BDP_REGISTER_MESSAGE(BDPWarmBootMessage, self)
    }
    return self;
}

- (void)dealloc
{
//    BDP_UNREGISTER_MESSAGE(BDPWarmBootMessage, self)
}

#pragma mark - app

- (NSString *)prefetchesFolderPathForAppId:(NSString *)appId {
    if (BDPSafeString(appId)) {
        OPAppUniqueID * uniqueId = [OPAppUniqueID uniqueIDWithAppID:appId identifier:nil versionType:OPAppVersionTypeCurrent appType:OPAppTypeGadget];
        return [[BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager] appBasicPathWithUniqueID:uniqueId];
    } else {
        return @"";
    }
}

- (NSString *)prefetchesFilePathForAppId:(NSString *)appId   {
    return appId.length ? [[self prefetchesFolderPathForAppId:appId] stringByAppendingPathComponent:PrefetchFileName] : @"";
}

- (void)getCacheInfoWithAppId:(NSString *)appId syncBlk:(void (^)(NSString *version, NSDictionary *cacheDict))syncBlk   {
    if (!appId.length || !syncBlk) {
        return;
    }
    NSString *filePath = [self prefetchesFilePathForAppId:appId];
    NSDictionary *cacheDict = filePath ? [[LSFileSystem main] readDictFrom:filePath] : nil;
    syncBlk(cacheDict[PrefetchVersionKey], cacheDict);
}

- (void)decodeWithConfigData:(NSData *)configData uniqueID:(BDPUniqueID*)uniqueID version:(NSString *)version {
    if (!configData.length || !uniqueID.appID.length || !version.length) {
        return;
    }
    [self decodeWithConfigDict:[configData JSONDictionary] uniqueID:uniqueID version:version completion:nil];
}

- (void)decodeWithConfigDict:(NSDictionary *)dict
                    uniqueID:(BDPUniqueID*)uniqueID
                     version:(NSString *)version
                  completion:(void (^)(NSDictionary *cacheDict))completion { // 缓存字典, 具体Key看置顶
    if (!dict.count || !uniqueID.appID.length || !version.length) {
        return;
    }
    __block NSDictionary *cacheDict = nil;
    __block BOOL hasCache = NO;
    [self getCacheInfoWithAppId:uniqueID.appID syncBlk:^(NSString *iVersion, NSDictionary *savedCacheDict) {
        hasCache = iVersion && [iVersion isEqualToString:version];
        cacheDict = savedCacheDict;
    }];
    
    // 没有对应版本的缓存,并且有prefetches数据则写入
    NSDictionary *prefetches = BDPSafeDictionary([dict bdp_dictionaryValueForKey:@"prefetches"]);
    NSDictionary *prefetchRules = BDPSafeDictionary([dict bdp_dictionaryValueForKey:@"prefetchRules"]); // prefetchRules 数据预取V2新增
    if ((!hasCache && (prefetches.count > 0 || prefetchRules.count > 0)) || uniqueID.versionType != OPAppVersionTypeCurrent) {
        NSString *entryPagePath = [dict bdp_stringValueForKey:@"entryPagePath"] ?: @"";
        cacheDict = @{
            PrefetchVersionKey: version,
            PrefetchListKey: prefetches,
            PrefetchHitRulesListKey: prefetchRules,
            PrefetchBackUpPathKey: entryPagePath,
        };
        // 存appid对应的目录下, 文件系统管理会一并删除掉
        NSString *filePath = [self prefetchesFilePathForAppId:uniqueID.appID];
        if (filePath) {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
                // 如果文件目录没了, 就不写入了
                if ([LSFileSystem fileExistsWithFilePath:[filePath stringByDeletingLastPathComponent] isDirectory:nil]) {
                    [[LSFileSystem main] writeWithDict:cacheDict to:filePath];
                }
            });
        }
    }
    
    BLOCK_EXEC(completion, cacheDict);
}

- (void)decodeAndPrefetchWithConfigDict:(NSDictionary *)configDict schema:(BDPSchema *)schema uniqueID:(BDPUniqueID*)uniqueID version:(NSString *)version {
    if (!configDict.count || !schema.appID.length || !version.length) {
        return;
    }
    
    WeakSelf;
    [self decodeWithConfigDict:configDict uniqueID:uniqueID version:version completion:^(NSDictionary *cacheDict) {
        StrongSelfIfNilReturn;
        BDPAppPagePrefetcher *prefetcher = [self getPrefetcherWithUniqueID:uniqueID];
        [prefetcher prefetchWithSchema:schema prefetchDict:cacheDict[PrefetchListKey] prefetchRulesDict:cacheDict[PrefetchHitRulesListKey] backupPath:cacheDict[PrefetchBackUpPathKey] isFromPlugin:NO];
    }];
}

- (BDPAppPagePrefetcher *)getPrefetcherWithUniqueID:(BDPUniqueID*)uniqueID
{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    BDPAppPagePrefetcher *prefetcher = [self.prefetcherDic objectForKey:uniqueID.appID];
    dispatch_semaphore_signal(self.semaphore);
    if (!prefetcher && uniqueID.appID) {
        prefetcher = [[BDPAppPagePrefetcher alloc] initWithUniqueID:uniqueID];
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        [self.prefetcherDic setObject:prefetcher forKey:uniqueID.appID];
        dispatch_semaphore_signal(self.semaphore);
    }
    return prefetcher;
}

- (void)prefetchWithCurrentSchema:(BDPSchema *)schema uniqueID:(BDPUniqueID*)uniqueID
{
    WeakSelf;
    [self getCacheInfoWithAppId:schema.appID syncBlk:^(NSString *version, NSDictionary *cacheDict) {
        StrongSelfIfNilReturn
        if (cacheDict) {
            BDPAppPagePrefetcher *prefetcher = [self getPrefetcherWithUniqueID:uniqueID];
            [prefetcher prefetchWithSchema:schema prefetchDict:cacheDict[PrefetchListKey] prefetchRulesDict:cacheDict[PrefetchHitRulesListKey] backupPath:cacheDict[PrefetchBackUpPathKey] isFromPlugin:NO];
        }
    }];
}

- (BOOL)shouldUsePrefetchCacheWithParam:(NSDictionary*)param
                               uniqueID:(BDPUniqueID *)uniqueID
                      requestCompletion:(PageRequestCompletionBlock)completion
                                  error:(OPPrefetchErrnoWrapper **)error
{
    BDPAppPagePrefetcher *prefetcher = [self getPrefetcherWithUniqueID:uniqueID];
    return [prefetcher shouldUsePrefetchCacheWithParam:param uniqueID:uniqueID requestCompletion:completion error:error];
}

- (void)releasePrefetcherWithUniqueID:(BDPUniqueID*)uniqueID
{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self.prefetcherDic removeObjectForKey:uniqueID.appID];
    dispatch_semaphore_signal(self.semaphore);
}

#pragma mark - plugin

- (void)decodeAndPrefetchPluginConfig:(NSDictionary *)configDict schema:(BDPSchema *)schema uniqueID:(BDPUniqueID*)uniqueID
{
    BDPAppPagePrefetcher *prefetcher = [self getPrefetcherWithUniqueID:uniqueID];
    [prefetcher prefetchWithSchema:schema prefetchDict:BDPSafeDictionary([configDict bdp_dictionaryValueForKey:@"prefetches"]) prefetchRulesDict:BDPSafeDictionary([configDict bdp_dictionaryValueForKey:@"prefetchRules"]) backupPath:[configDict bdp_stringValueForKey:@"entryPagePath"] isFromPlugin:YES];
}

#pragma mark - Message
/*-----------------------------------------------*/
//                  Message
/*-----------------------------------------------*/
//- (void)cleanWarmCacheWithUniqueID:(BDPUniqueID *)uniqueID
//{
//    [self releasePrefetcherWithUniqueID:uniqueID];
//}

#pragma mark - settings

- (BOOL)isAllowPrefetchWithSchema:(BDPSchema *)schema
{
    //目前允许所有小程序使用prefetch功能
    //通过 “bdp_startpage_prefetch.enable” 统一切功能入口
    return YES;
}

-(void)logout
{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self.prefetcherDic removeAllObjects];
    dispatch_semaphore_signal(self.semaphore);
}

@end
