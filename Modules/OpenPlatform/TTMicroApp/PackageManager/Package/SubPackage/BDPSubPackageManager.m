//
//  BDPSubPackageManager.m
//  TTMicroApp
//
//  Created by Nicholas Tau on 2021/8/25.
//

#import "BDPSubPackageManager.h"
#import <OPFoundation/EEFeatureGating.h>
#import "BDPPackageModuleProtocol.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPMacroUtils.h>
#import "BDPPackageStreamingFileHandle.h"
#import "BDPAppLoadDefineHeader.h"
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/BDPCommonManager.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/ECOConfig.h>
#import <ECOInfra/ECOConfigService.h>
#import "BDPGadgetLog.h"
#import <OPFoundation/BDPMonitorEvent.h>
#import "BDPModel+PackageManager.h"
#import "BDPPkgFileBasicModel.h"

@interface NSString(SubPackageFix)
/// 字符添加/后缀
/// 分包下发的路径可能不带/，会被客户端误判，做个兼容处理
-(NSString *)_withSlashAppending;
@end

@implementation NSString  (SubPackageFix)
-(NSString *)_withSlashAppending {
    if ([self hasSuffix:@"/"]) {
        return self;
    } else {
        return [self stringByAppendingString:@"/"];
    }
}
@end

static NSString * const kLogTagSubPacakge = @"TTMicroApp.BDPSubPackageManager";

@interface  BDPSubPackageManager()
@property (nonatomic, strong) NSMutableDictionary * fileReaderMap;
@property (nonatomic, strong) dispatch_semaphore_t fileReaderSemaphore;
@property (nonatomic, strong) dispatch_queue_t workQueue;//串行队列
@property (nonatomic, strong) dispatch_queue_t downloadQueue;//串行队列
@end

@implementation BDPSubPackageManager
+ (instancetype)sharedManager {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDPSubPackageManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.fileReaderMap = @{}.mutableCopy;
        self.fileReaderSemaphore = dispatch_semaphore_create(1);
        _workQueue = dispatch_queue_create("com.bytedance.openplatform.subpackageWorkQueue", DISPATCH_QUEUE_SERIAL);
        _downloadQueue = dispatch_queue_create("com.bytedance.openplatform.subpackageDownloadQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(BOOL)enableSubPackageWithUniqueId:(OPAppUniqueID *)uniqueId
{
    id<ECOConfigService> service = [ECOConfig service];
    //获取白名单中允许从storage中读取的keys，不能全开
    NSDictionary<NSString *, id> * subPackageConfig = BDPSafeDictionary([service getDictionaryValueForKey: @"open_split_package_config"]);
    BOOL subPackageEnable = NO;
    //黑名单里存在，直接禁用
    if ([BDPSafeArray(subPackageConfig[@"disabledAppIdList"]) containsObject:uniqueId.appID]) {
        subPackageEnable = NO;
    } else if ([BDPSafeArray(subPackageConfig[@"enabledAppIdList"]) containsObject:uniqueId.appID]) {
        subPackageEnable = YES;
    } else {
        subPackageEnable = [subPackageConfig bdp_boolValueForKey2:@"enabled"];
    }
    // 如果结果不允许打开, 则日志记录一下.
    if (!subPackageEnable) {
        BDPGadgetLogTagInfo(kLogTagSubPacakge, @"uniqueId: %@, subpackageEnable: %d", uniqueId.fullString, subPackageEnable);
    }

    return subPackageEnable;
}

-(void)cleanFileReadersWithUniqueId:(BDPUniqueID *)uniqueID
{
    NSMutableArray * removeKeys = @[].mutableCopy;
    LOCK(self.fileReaderSemaphore, {
        [self.fileReaderMap enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, BDPPackageStreamingFileHandle *  _Nonnull reader, BOOL * _Nonnull stop) {
            //如果Path匹配到或者path和目标的page都为空（主包），都作为匹配结果返回
            if ([reader basic].uniqueID == uniqueID){
                [removeKeys addObject:key];
            }
        }];
        [self.fileReaderMap removeObjectsForKeys:removeKeys];
    })
}

-(void)cleanAllReaders
{
    LOCK(self.fileReaderSemaphore, [self.fileReaderMap removeAllObjects]);
}

-(void)updateFileReader:(id<BDPPkgFileReadHandleProtocol> _Nullable)fileReader withPackageContext:(BDPPackageContext *)context
{
    LOCK(self.fileReaderSemaphore, self.fileReaderMap[context.packageName] = fileReader)
}

-(id<BDPPkgFileReadHandleProtocol> _Nullable)getFileReaderWithPackageName:(NSString *)packageName
{
    id<BDPPkgFileReadHandleProtocol> fileReader = nil;
    LOCK(self.fileReaderSemaphore, fileReader = self.fileReaderMap[packageName])
    return fileReader;
}

- (id<BDPPkgFileReadHandleProtocol> _Nullable)getFileReaderWithPackageContext:(BDPPackageContext *)context
{
    return [self getFileReaderWithPackageName:context.packageName];
}

-(id<BDPPkgFileReadHandleProtocol> _Nullable)getFileReaderWithPagePath:(NSString * _Nullable) pagePath uniqueID:(BDPUniqueID *)uniqueID
{
    id<BDPPkgFileReadHandleProtocol> fileReader = nil;
    id<BDPPkgFileReadHandleProtocol> mainPackageReader = nil;
    LOCK(self.fileReaderSemaphore, {
        for(BDPPackageStreamingFileHandle * reader in self.fileReaderMap.allValues) {
            if([reader isKindOfClass:[BDPPackageStreamingFileHandle class]] &&
               [reader.packageContext.uniqueID isEqual:uniqueID]) {
                //如果Path匹配到或者path和目标的page都为空（主包），都作为匹配结果返回
                if ([reader basic].pagePath==nil){
                    //两边 pagePath 都是nil，默认是主包
                    if (pagePath == nil ||
                        //如果当前render是个主包，且目标pagePath在页面数组中，默认匹配
                        [reader.packageContext.metaSubPackage.pages containsObject:pagePath]) {
                        fileReader = reader;
                    }
                } else if([pagePath hasPrefix:[reader basic].pagePath._withSlashAppending]) {
                    fileReader = reader;
                }
                if(reader.packageContext.subPackageType == BDPSubPkgTypeMain){
                    mainPackageReader = reader;
                }
            }
        }
    })
    //app.js, app-service.js会直接传，无法通过目录匹配。默认在主包里，需要用主包兜底
    if (!fileReader&&mainPackageReader) {
        BDPGadgetLogWarn(@"getFileReaderWithPagePath:%@ error, fileReader is nil, mainPackageReader will return:%@ with pkgName:%@", pagePath, mainPackageReader, [[mainPackageReader basic] pkgName]);
        fileReader = mainPackageReader;
    }
    return fileReader;
}

- (void)prepareSubPackagesWithContext:(BDPPackageContext *)context
                             priority:(float)priority
                                begun:(BDPPackageDownloaderBegunBlock)begunBlock
                             progress:(BDPPackageDownloaderProgressBlock)progressBlock
                            completed:(BDPPackageDownloaderCompletedBlock)completedBlock
{
    //先检查分包是否存在，没有则进行下载
    //拿到启动页需要的分包，可能是以下三种组合
    //主包、主包+分包、独立分包
    NSArray<BDPPackageContext *> * requiredSubPackages = [context requiredSubPackagesWithPagePath:context.startPage];
    //如果启动时发现有包已经下载好了，直接装载 reader上下文
    BDPResolveModule(packageModule, BDPPackageModuleProtocol, OPAppTypeGadget)
    NSArray<BDPPackageContext *> * allPackages = [context subPackages];
    for (BDPPackageContext * packageContext in allPackages) {
         id<BDPPkgFileManagerHandleProtocol> packageReaderContext = [packageModule checkLocalPackageReaderWithContext:packageContext];
        if (packageReaderContext) {
            [self updateFileReader:packageReaderContext
                withPackageContext:packageContext];
        }
    }
    [self downloadSubPackages:requiredSubPackages
                     priority:1
                        begun:begunBlock
                     progress:progressBlock
                    completed:completedBlock];
}

- (void)downloadSubPackages:(NSArray<BDPPackageContext *> *)subPackages
                   priority:(float)priority
                      begun:(BDPPackageDownloaderBegunBlock)begunBlock
                   progress:(BDPPackageDownloaderProgressBlock)progressBlock
                  completed:(BDPPackageDownloaderCompletedBlock)completedBlock
{
    BDPGadgetLogTagInfo(kLogTagSubPacakge, @"downloadSubPackages start with subpackages count:%@", @(subPackages.count));
    //按顺序执行下载, 先下载第0 个【主包、独立分包】，后下载分包【若有】
    BDPResolveModule(packageModule, BDPPackageModuleProtocol, OPAppTypeGadget)
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        WeakSelf;
        dispatch_semaphore_t syncWaitSemphore = dispatch_semaphore_create(0);
        for (BDPPackageContext * subPackage in subPackages) {
            BOOL isFirstSubPackage = [subPackages indexOfObject:subPackage] == 0;
            //封装一次begunblock，读本地缓存文件时为了保存 reader
            BDPPackageDownloaderBegunBlock begunCallback = isFirstSubPackage ? ^(id<BDPPkgFileManagerHandleProtocol> packageReader){
                if (begunBlock) {
                    begunBlock(packageReader);
                }
                StrongSelfIfNilReturn
                //把 Reader按package信息存起来
                [self updateFileReader:(id<BDPPkgFileReadHandleProtocol>)packageReader withPackageContext:subPackage];
            } : nil;
            BDPPackageDownloaderProgressBlock progressCallback = isFirstSubPackage ? progressBlock : nil;
            //如果是首个分包，需要回调且结束后释放信号量。否则只需要释放信号量
            BDPPackageDownloaderCompletedBlock completeCallback = isFirstSubPackage ? ^(OPError * _Nullable error, BOOL cancelled, id<BDPPkgFileManagerHandleProtocol> _Nullable packageReader){
                //先执行complete回调
                if (completedBlock) {
                    completedBlock(error, cancelled, packageReader);
                }
                StrongSelfIfNilReturn
                //把 Reader按package信息存起来
                [self updateFileReader:(id<BDPPkgFileReadHandleProtocol>)packageReader withPackageContext:subPackage];
                dispatch_semaphore_signal(syncWaitSemphore);
            } : ^(OPError * _Nullable error, BOOL cancelled, id<BDPPkgFileManagerHandleProtocol> _Nullable packageReader){
                StrongSelfIfNilReturn
                //把 Reader按package信息存起来
                [self updateFileReader:(id<BDPPkgFileReadHandleProtocol>)packageReader withPackageContext:subPackage];
                dispatch_semaphore_signal(syncWaitSemphore);
            };
            [packageModule fetchSubPackageWithContext:subPackage
                                       localCompleted:^(id<BDPPkgFileManagerHandleProtocol>  _Nonnull packageReader) {
                                            if(completeCallback){
                                                completeCallback(nil, NO, packageReader);
                                            }}
                                     downloadPriority:priority
                                        downloadBegun:begunCallback
                                     downloadProgress:progressCallback
                                    downloadCompleted:completeCallback];
            dispatch_semaphore_wait(syncWaitSemphore, DISPATCH_TIME_FOREVER);
        }
    });
}

- (void)preloadWithRulesInPagePath:(NSString *)pagePath
                      withUniqueID:(BDPUniqueID *)uniqueID {
    dispatch_async(self.workQueue, ^{
        [self private_preloadWithRulesInPagePath:pagePath withUniqueID:uniqueID];
    });
}

// 分包预加载具体实现.分包配置多可能涉及耗时操作.
- (void)private_preloadWithRulesInPagePath:(NSString *)pagePath
                              withUniqueID:(BDPUniqueID *)uniqueID {
    //入参校验
    if (BDPIsEmptyString(pagePath) ||
        !uniqueID.isValid) {
        //遇加载功能没开启
        BDPGadgetLogTagWarn(kLogTagSubPacakge, @"preloadWithRulesInPagePath determinated, parameters checking fail, uniqueID: %@", uniqueID.fullString);
        return;
    }

    BDPGadgetLogTagInfo(kLogTagSubPacakge, @"start preload sub package uniqueId: %@ pagePath: %@", uniqueID.fullString, pagePath);

    //先检查是不是开启了开关配置
    id<ECOConfigService> service = [ECOConfig service];
    NSDictionary<NSString *, id> *preloadSubpackgeParams = BDPSafeDictionary([service getLatestDictionaryValueForKey: @"openplatform_gadget_preload"])[@"preload_subpackage"];
    if (![preloadSubpackgeParams bdp_boolValueForKey2:@"enable"]) {
        //预加载功能没开启
        BDPGadgetLogTagWarn(kLogTagSubPacakge, @"preloadWithRulesInPagePath disable");
        return;
    }
    //再找到是否有被关联的分包预加载配置，没有就return
    BDPTask *currentTask = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
    NSDictionary *allPreloadRule = BDPSafeDictionary(currentTask.config.preloadRule);
    NSArray<NSDictionary *> *subPackagesFromConfig = BDPSafeArray(currentTask.config.subPackages);
    NSDictionary *preloadRule = nil;
    for (NSString *key in allPreloadRule.allKeys) {
        if ([pagePath hasPrefix:key._withSlashAppending]) {
            preloadRule = [allPreloadRule bdp_dictionaryValueForKey:key];
            BDPGadgetLogTagInfo(kLogTagSubPacakge, @"pagePath: %@ map subDirectory: %@", pagePath, key);
            break;
        }
    }

    if (BDPIsEmptyDictionary(preloadRule)) {
        BDPGadgetLogTagWarn(kLogTagSubPacakge, @"can not found subpackage config from app.json for page: %@", pagePath);
        return;
    }

    // 分包预加载中配置的路径
    NSArray<NSString *> *packagesFromPreloadRule = BDPSafeArray([preloadRule bdp_arrayValueForKey:@"packages"]);

    // 分包预加载的路径.(已经将别名替换成路径, 如果还存在别名, 则是因为appConfig中的name与分包预加载中name不一致)
    NSArray<NSString *> *packages = [self removeNamePreloadSubpackages:packagesFromPreloadRule configSubpackages:subPackagesFromConfig];

    if (packages.count == 0) {
        BDPGadgetLogTagWarn(kLogTagSubPacakge, @"preloadWithRulesInPagePath determinated, because preloadRule is empty");
        return;
    }

    // 预加载网络配置, 这边要判断当前网络状态是否满足分包预加载的条件
    NSString *networkType = BDPSafeString([preloadRule bdp_stringValueForKey:@"network"]);
    if ([networkType isEqualToString:@"wifi"] && ![BDPCurrentNetworkType() isEqualToString:@"wifi"]) {
        BDPGadgetLogTagWarn(kLogTagSubPacakge, @"can not download sub package without wifi, current networkType: %@", BDPCurrentNetworkType());
        return;
    }

    //获取关联配置最大预加载数
    //先看是不是有指定AppID的配置，没有就是用最外面的配置
    NSDictionary *preloadQueueCountCfg = preloadSubpackgeParams[uniqueID.appID] ?: preloadSubpackgeParams;
    //获取 queueCount，没有就默认是5
    NSInteger maxQueueCount = [preloadQueueCountCfg bdp_integerValueForKey:@"default_count"] ?: 5;
    //计算需要遇加载到页面内的资源包
    GadgetMeta *gadgetMeta = [[BDPCommonManager.sharedManager getCommonWithUniqueID:uniqueID].model toGadgetMeta];
    if (gadgetMeta == nil) {
        BDPGadgetLogTagWarn(kLogTagSubPacakge, @"gadgetMeta is nil");
        return;
    }

    BDPPackageContext *packageContext = [[BDPPackageContext alloc] initWithAppMeta:gadgetMeta
                                                                       packageType:BDPPackageTypePkg
                                                                       packageName:nil
                                                                             trace:nil];

    //搞个临时表，存储页面 pagePath 和 package之间的关系。减少匹配遍历次数
    NSMutableDictionary *subPackagesConfig = @{}.mutableCopy;
    for (BDPPackageContext *subPackage in packageContext.subPackages) {
        // 这边对meta中的路径末尾拼接上"/"
        NSString *path = BDPSafeString([subPackage.metaSubPackage.path bdp_fileUrlAddDirectoryPathIfNeeded]);
        subPackagesConfig[path] = subPackage;
    }
    //找到需要遇加载的包
    NSMutableArray *preloadPackages = [NSMutableArray arrayWithCapacity:maxQueueCount];
    if(packages.count > maxQueueCount) {
        BDPGadgetLogTagWarn(kLogTagSubPacakge, @"preloadWithRulesInPagePath packages will be dropped because count(%@) out of capacity:(%@)", @(packages.count), @(maxQueueCount));
    }

    [packages enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *packageName = [BDPSafeString(obj) bdp_fileUrlAddDirectoryPathIfNeeded];
        if (packageName.length > 0 && subPackagesConfig[packageName]) {
            [preloadPackages addObject:subPackagesConfig[packageName]];
        }
        //之后的会被删除
        *stop = idx >= (maxQueueCount - 1);
    }];

    // 当前页面没有关联预加载分包, 则不需要进行下载
    if (preloadPackages.count == 0) {
        BDPGadgetLogTagInfo(kLogTagSubPacakge, @"current page: %@ need preload subpackage is 0", pagePath);
        return;
    }

    // 延迟加载的时间(单位毫秒)
    NSInteger delayInterval = [preloadSubpackgeParams integerValueForKey:@"delay_ms" defaultValue:2000];
    //延迟开始串行预加载任务
    WeakSelf;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInterval * NSEC_PER_MSEC)), self.downloadQueue, ^{
        //开始串行任务，一个个下载 preloadPackages 里的内容
        //用来保证串行执行的锁, 在每一个分包下载完成(completionCallback)后解锁
        dispatch_semaphore_t syncWaitSemphore = dispatch_semaphore_create(0);
        BDPResolveModule(packageModule, BDPPackageModuleProtocol, OPAppTypeGadget)
        for (BDPPackageContext *preloadPackage in preloadPackages) {
            NSString *page_path = BDPSafeString(preloadPackage.metaSubPackage.path);
            // 埋点上报
            BDPMonitorWithCode([[OPMonitorCode alloc] initWithCode:EPMClientOpenPlatformCommonPackageCode.mp_preload_sub_package_start], uniqueID)
                    .addCategoryValue(@"page_path", page_path)
                    .addCategoryValue(@"network", networkType)
                    .flush();

            BDPMonitorEvent *resultMonitor = BDPMonitorWithCode([[OPMonitorCode alloc] initWithCode:EPMClientOpenPlatformCommonPackageCode.mp_preload_sub_package_result], uniqueID);

            resultMonitor
                .addCategoryValue(@"page_path", page_path)
                .addCategoryValue(@"network", networkType)
                .timing();
            BDPPackageDownloaderCompletedBlock completeCallback = ^(OPError * _Nullable error, BOOL cancelled, id<BDPPkgFileManagerHandleProtocol> _Nullable packageReader) {
                StrongSelfIfNilReturn;
                //埋点上报
                if (error) {
                    resultMonitor.setResultTypeFail();
                    BDPGadgetLogTagError(kLogTagSubPacakge, @"pre download %@ subpackage failed: %@", page_path, error);
                } else {
                    resultMonitor.setResultTypeSuccess();
                }
                resultMonitor.timing().flush();

                //把 Reader按package信息存起来
                [self updateFileReader:(id<BDPPkgFileReadHandleProtocol>)packageReader withPackageContext:preloadPackage];

                dispatch_semaphore_signal(syncWaitSemphore);
            };
            // 下载分包
            [packageModule fetchSubPackageWithContext:preloadPackage
                                       localCompleted:^(id<BDPPkgFileManagerHandleProtocol>  _Nonnull packageReader) {
                if(completeCallback) {
                    completeCallback(nil, NO, packageReader);
                }
            }
                                     downloadPriority:1
                                        downloadBegun:nil
                                     downloadProgress:nil
                                    downloadCompleted:completeCallback];
            dispatch_semaphore_wait(syncWaitSemphore, DISPATCH_TIME_FOREVER);
        }
    });
}

-(BDPPackageContext *)packageContextWithPath:(NSString*)path uniqueID:(BDPUniqueID *)uniqueID
{
    //    id<AppMetaProtocol> meta = [MetaLocalAccessorBridge getMetaWithUniqueIdWithUniqueID:uniqueID];
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
    id<AppMetaProtocol> meta = common.model.toGadgetMeta;
    BDPPackageContext * subPackageContext = nil;
    if (meta) {
        BDPPackageContext * packageContext = [[BDPPackageContext alloc] initWithAppMeta:meta
                                                                            packageType:BDPPackageTypePkg
                                                                            packageName:nil
                                                                                  trace:nil];
        if (packageContext.subPackages) {
            //这里是进入分包页的场景。只需要确保动态获取对应的分包即可，
            BDPPackageContext * mainSubPackageContext = nil;
            for (BDPPackageContext * package in packageContext.subPackages) {
                if ([path hasPrefix:package.metaSubPackage.path._withSlashAppending] ) {
                    subPackageContext = package;
                    break;
                }
                if(package.subPackageType == BDPSubPkgTypeMain){
                    mainSubPackageContext = package;
                }
            }
            //如果 subPackageContext 已经找到包上下文了，默认使用
            //否则用主包兜底。主包的跳转路径(bap_path)是 page/index（meta 里用了__APP__），需要特殊处理一下
            subPackageContext = subPackageContext ?: mainSubPackageContext;
        }
    }
    return subPackageContext;
}

-(void)prepareSubPackagesForPage:(NSString *)pagePath
                    withUniqueID:(BDPUniqueID *)uniqueID
                        isWorker:(BOOL)isWorker
               jsExecuteCallback:(nonnull BDPSubPackageJSExcutedCallback)callback
{
    //每次更新跳转都会调用到这里，可以在这里检查对应的分包是否下载完成
    //如果没有下载完成则进行下载【首屏页不会执行到这里】
    if (![[BDPSubPackageManager sharedManager] enableSubPackageWithUniqueId:uniqueID]) {
        //分包没有开启，直接中断分包下载逻辑
        return;
    }
//    id<AppMetaProtocol> meta = [MetaLocalAccessorBridge getMetaWithUniqueIdWithUniqueID:uniqueID];
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
    id<AppMetaProtocol> meta = common.model.toGadgetMeta;
    if (meta) {
        BDPResolveModule(packageModule, BDPPackageModuleProtocol, uniqueID.appType)
        BDPPackageContext * packageContext = [[BDPPackageContext alloc] initWithAppMeta:meta
                                                                            packageType:BDPPackageTypePkg
                                                                            packageName:nil
                                                                                  trace:nil];
        if (packageContext.subPackages) {
            WeakSelf;
            //这里是进入分包页的场景。只需要确保动态获取对应的分包即可，
            BDPPackageContext * subPackageContext = nil;
            BDPPackageContext * mainSubPackageContext = nil;
            for (BDPPackageContext * package in packageContext.subPackages) {
                if ([pagePath hasPrefix:package.metaSubPackage.path._withSlashAppending] ) {
                    subPackageContext = package;
                    break;
                }
                if(package.subPackageType == BDPSubPkgTypeMain){
                    mainSubPackageContext = package;
                }
            }
            //如果 subPackageContext 已经找到包上下文了，默认使用
            //否则用主包兜底。主包的跳转路径(bap_path)是 page/index（meta 里用了__APP__），需要特殊处理一下
            subPackageContext = subPackageContext ?: mainSubPackageContext;
            BDPGadgetLogInfo(@"prepareSubPackagesForPage with pagePath:%@ and matched result %@ with packageName:%@", pagePath, subPackageContext, subPackageContext.packageName);
            if (subPackageContext) {
                [subPackageContext updateStartPage:pagePath];
                
                BDPPackageDownloaderBegunBlock begunBlock = ^(id<BDPPkgFileManagerHandleProtocol>  _Nullable packageReader) { //获取流失包下载句柄
                    BDPPackageStreamingFileHandle * streamFileHandle = (BDPPackageStreamingFileHandle*) packageReader;
                    StrongSelfIfNilReturn;
                    NSString * fileHandlePath = [streamFileHandle basic].pagePath;
                    //如果Path匹配，或者pagePath为空（主包）需要执行JS补偿
                    if((fileHandlePath&&[pagePath hasPrefix:fileHandlePath._withSlashAppending])|| !fileHandlePath){
                        callback(BDPSubPackageLoadAppPrepare, nil);
                        if(isWorker){
                            [self executeExtraAppServiceJSWith:streamFileHandle
                                                    targetPath:fileHandlePath
                                                  sepcificPage:pagePath
                                             jsExecuteCallback:callback];
                        }else{
                            //执行分包的 page-frame.js 加载任务
                            [self executeExtraPageFrameJSWith:streamFileHandle
                                                   targetPath:fileHandlePath
                                                 sepcificPage:pagePath
                                            jsExecuteCallback:callback];
                        }
                    } else {
                        BDPGadgetLogError(@"prepareSubPackagesForPage with error, unknow fileHandlePath:%@", fileHandlePath);
                    }
                    
                };
                id<BDPPkgFileManagerHandleProtocol>  _Nullable cachedPackageReader = [self getFileReaderWithPackageContext:subPackageContext];
                if (cachedPackageReader) {
                    begunBlock(cachedPackageReader);
                }else{
                    [[BDPSubPackageManager sharedManager] downloadSubPackages:@[subPackageContext]
                                                                     priority:1
                                                                        begun:begunBlock
                                                                     progress:nil
                                                                    completed:nil];
                }
            } else {
                BDPGadgetLogError(@"prepareSubPackagesForPage with error, subPackageContext not found:%@", pagePath);
            }
        } else {
            BDPGadgetLogError(@"prepareSubPackagesForPage with error, packageContext.subPackages is nil");
        }
    } else {
        BDPGadgetLogError(@"prepareSubPackagesForPage with error, meta is nil");
    }
}

/// 开始执行额外的app-servcie.js
/// @param fileReader
/// @param pagePath page/API【共同路径】
/// @param sepcificPath page/API/video/video 页面详细路径
-(void)executeExtraAppServiceJSWith:(BDPPackageStreamingFileHandle *)fileReader
                         targetPath:(NSString *)pagePath
                       sepcificPage:(NSString *)sepcificPath
                  jsExecuteCallback:(BDPSubPackageJSExcutedCallback)unsafeCallback
{
    BDPGadgetLogInfo(@"executeExtraAppServiceJSWith %@, %@, %@", fileReader, pagePath, sepcificPath);
    BDPUniqueID * uniqueID = fileReader.packageContext.uniqueID;
    BDPTask * task = BDPTaskFromUniqueID(uniqueID);
    NSString* appServiceJS = pagePath ? [pagePath stringByAppendingPathComponent:@"app-service.js"] : @"app-service.js";
    BDPSubPackageJSExcutedCallback callback = unsafeCallback ?: ^(BDPSubPackageExtraJSLoadStep loadStep, NSError * _Nullable error) {
        BDPGadgetLogInfo(@"executeExtraAppServiceJSWith safe callback been invoked: %@, %@, %@", fileReader, pagePath, sepcificPath);
    };
    if(![task.context.executedJSPathes containsObject:appServiceJS]){
        //没有执行过，执行一次分包的app-service.js
        WeakSelf;
        [fileReader readDataInOrder:NO
                       withFilePath:appServiceJS
                         dispatchQueue:dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
                            completion:^(NSError * _Nullable error, NSString * _Nonnull pkgName, NSData * _Nullable data) {
            callback(BDPSubPackageLoadAppServiceBegin, error);
            StrongSelfIfNilReturn;
            if (error) {
                error = OPErrorWithError(GDMonitorCode.load_app_service_script_error, error);
                BDP_PKG_LOAD_LOG(@"%@ not found!!!: %@", appServiceJS, error);
                [OPSDKRecoveryEntrance handleErrorWithUniqueID:uniqueID
                                                          with:(OPError *)error
                                                 recoveryScene:RecoveryScene.gadgetRuntimeFail
                                                contextUpdater:nil];
                return;
            }
            NSString *script = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (!BDPIsEmptyString(script) && task.context) {
                WeakSelf;
                [task.context loadScript:script withFileSource:appServiceJS callbackIsMainThread:YES completion:^{
                    BDPGadgetLogInfo(@"[BDPlatform-App] Loading %@", appServiceJS);
                    StrongSelfIfNilReturn;
                    callback(BDPSubPackageLoadAppServiceEnd, nil);
                }];
            } else {
                NSString * errorInfo = BDPIsEmptyString(script) ? @"script is empty" : @"task.context is nil";
                if (!error) {
                    error = OPErrorWithErrorAndMsg(GDMonitorCodeAppLoad.pkg_data_parse_failed, error, @"data(%@) in pkg parse failed: %@, extra error:%@", uniqueID, appServiceJS, errorInfo);
                }
                [OPSDKRecoveryEntrance handleErrorWithUniqueID:uniqueID
                                                          with:(OPError *)error
                                                 recoveryScene:RecoveryScene.gadgetRuntimeFail
                                                contextUpdater:nil];
            }
        }];
    } else {
        //executedJSPathes 已经执行过了，
        //直接直接通知外部 appService ended，以便注册appRoute等事件
        callback(BDPSubPackageLoadAppServiceEnd, nil);
    }
}

/// 开始执行额外的page-frame.js
/// @param fileReader
/// @param pagePath page/API【共同路径】
/// @param sepcificPath page/API/video/video 页面详细路径
-(void)executeExtraPageFrameJSWith:(BDPPkgFileReader _Nullable)fileReader
                        targetPath:(NSString *)pagePath
                      sepcificPage:(NSString *)sepcificPath
                 jsExecuteCallback:(BDPSubPackageJSExcutedCallback)unsafeCallback
{
    BDPGadgetLogInfo(@"executeExtraPageFrameJSWith fileReader:%@, pagePath:%@, sepcificPath:%@", fileReader, pagePath, sepcificPath);
    if(fileReader==nil||![fileReader isKindOfClass:[BDPPackageStreamingFileHandle class]]){
        BDPGadgetLogError(@"executeExtraPageFrameJSWith: fileReader invalid!!!");
        return;
    }
    BDPSubPackageJSExcutedCallback callback = unsafeCallback ?: ^(BDPSubPackageExtraJSLoadStep loadStep, NSError * _Nullable error) {
        BDPGadgetLogInfo(@"executeExtraPageFrameJSWith safe callback been invoked: %@, %@, %@", fileReader, pagePath, sepcificPath);
    };
    BDPUniqueID * uniqueID = ((BDPPackageStreamingFileHandle*)fileReader).packageContext.uniqueID;
    BDPTask * task = BDPTaskFromUniqueID(uniqueID);
    BDPAppPage * appPage = [task.pageManager appPageWithPath:sepcificPath];
    if (appPage) {
        NSString * pageFramePath = pagePath ? [pagePath stringByAppendingPathComponent:@"page-frame.js"] : @"page-frame.js";
        WeakSelf;
        [fileReader readDataInOrder:NO
                       withFilePath:pageFramePath
                      dispatchQueue:nil
                         completion:^(NSError * _Nullable error, NSString * _Nonnull pkgName, NSData * _Nullable data) {
            StrongSelfIfNilReturn;
            if(error){
                BDPGadgetLogError(@"executeExtraPageFrameJSWith with error:%@", error);
                return;
            }
            NSString *pathScript = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            callback(BDPSubPackageLoadPageFrameBegin, error);
            void (^pathPageFrameScriptExecute)(void) = ^(){
                [appPage bdp_evaluateJavaScript:pathScript
                                     completion:^(id result, NSError *error) {
                    StrongSelfIfNilReturn;
                    if (!error) {
                        appPage.isSubPageFrameReady = YES;
                        //通知外部page-frame相关的资源都已经加载完毕，可以加载pathScript了
                        callback(BDPSubPackageLoadPageFrameEnd, error);
                    } else {
                        callback(BDPSubPackageLoadPageFrameEnd, error);
                        [OPSDKRecoveryEntrance handleErrorWithUniqueID:uniqueID
                                                                  with:OPErrorWithError(GDMonitorCode.load_path_frame_script_error, error)
                                                         recoveryScene:RecoveryScene.gadgetRuntimeFail
                                                        contextUpdater:nil];
                    }
                }];
            };
            
            //执行过common.render（有可能是独立分饱）里的page-frame.js了
            if (appPage.didLoadFrameScript) {
                //需在再执行分包对应页的page-frame.js（独立分包->主包）
                pathPageFrameScriptExecute();
            } else {
                //主page-frame.js没有准备好
                //先补偿执行一遍 page-frame.js，防止白屏
                BDPCommon * common =  [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
                [common.reader readDataWithFilePath:@"page-frame.js"
                                   syncIfDownloaded:YES
                                      dispatchQueue:nil
                                         completion:^(NSError * _Nullable error, NSString * _Nonnull pkgName, NSData * _Nullable data) {
                    NSString *pageFrameScript = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    [appPage bdp_evaluateJavaScript:pageFrameScript
                                         completion:^(id _Nullable, NSError * _Nullable error) {
                        pathPageFrameScriptExecute();
                    }];
                }];
            }
        }];
    } else {
        NSAssert(appPage != nil, @"appPage is nil, fatal error in sub-package");
        BDPGadgetLogError(@"executeExtraPageFrameJSWith: appPage is nil");
    }
}


/// 将preLoadRule中的分包别名替换成路径
/// @param preloadRulePackages preloadRule中配置的预加载分包数组
/// @param configSubpackages appConfig中的分包数组(别名只有在appConfig中有, meta中没有)
- (NSArray<NSString *> *)removeNamePreloadSubpackages:(NSArray<NSString *> *)preloadRulePackages
                        configSubpackages:(NSArray<NSDictionary *> *)configSubpackages {
    if (preloadRulePackages.count == 0) {
        return @[];
    }

    if (configSubpackages.count == 0) {
        return preloadRulePackages;
    }

    // 当preloadRule中的分包别名匹配上后, 就从该数组移除. 最终只保留路径的数组.
    NSMutableArray *preloadRulePackagesMut = [NSMutableArray arrayWithArray:preloadRulePackages];
    // 需要加载的分包数组, 将原来用户配置的分包数组中的别名被替换成路径.
    NSMutableArray *realPackages = [NSMutableArray array];

    //将预加载分包数组中的别名替换成路径.
    for (NSString *path in preloadRulePackages) {
        for (NSDictionary *subpackage in configSubpackages) {
            if (BDPIsEmptyDictionary(subpackage)) {
                BDPGadgetLogTagWarn(kLogTagSubPacakge, @"subpackages from config is invalid");
                continue;
            }
            NSString *name = subpackage[@"name"];
            // 匹配到别名,则将别名对应的root加入到数组中
            if (name && [path isEqualToString:name]) {
                [realPackages addObject:BDPSafeString(subpackage[@"root"])];
                [preloadRulePackagesMut removeObject:path];
                break;
            }
        }
    }

    // 如果还有未匹配上的路径, 则加入到realPackages
    if (preloadRulePackagesMut.count) {
        [realPackages addObjectsFromArray:preloadRulePackagesMut];
    }

    if (realPackages.count != preloadRulePackages.count) {
        BDPGadgetLogTagWarn(kLogTagSubPacakge, @"convert preloadSubpackages name to root get error");
    }

    return [realPackages copy];
}
@end

@implementation BDPCommon  (BDPSubPackageManager)
-(BOOL)isSubpackageEnable {
    return [[BDPSubPackageManager sharedManager] enableSubPackageWithUniqueId:self.uniqueID] && self.model.package.subPackages.count > 0;
}
@end

@implementation BDPPackageContext  (BDPSubPackageManager)
-(BOOL)isSubpackageEnable {
    return [[BDPSubPackageManager sharedManager] enableSubPackageWithUniqueId:self.uniqueID] && (self.subPackages.count > 0 || self.subPackageType > BDPSubPkgTypeMain);//主包之后是分包，分包的subPackages为空，但本身肯定是分包模式下的产物
}
@end
