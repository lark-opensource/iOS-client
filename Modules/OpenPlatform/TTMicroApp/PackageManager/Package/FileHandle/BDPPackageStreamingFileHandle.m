//
//  BDPPackageStreamingFileHandle.m
//  Timor
//
//  Created by houjihu on 2020/7/16.
//

#import "BDPPackageStreamingFileHandle.h"
#import "BDPPkgHeaderParser.h"
#import "BDPPkgHeaderInfo.h"
#import <OPFoundation/BDPMacroUtils.h>
#import "BDPPackageStreamingFileHandle+Private.h"
#import "BDPPackageStreamingFileHandle+WriteHandle.h"
#import "BDPPackageStreamingFileHandle+AsyncRead.h"
#import "BDPPackageStreamingFileHandle+SyncRead.h"
#import "BDPPackageStreamingFileHandle+FileManagerHandle.h"
#import "BDPPackageLocalManager.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "BDPSubPackageManager.h"
#import "BDPPkgFileBasicModel.h"

// 在category中实现BDPPkgFileReadHandleProtocol的各个子协议，这里屏蔽编译检查
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"

/** 全局串行队列, 用于处理音频文件读写的任务 */
dispatch_queue_t BDPPackageStreamingFileHandleSerialQueue;

@implementation BDPPackageStreamingFileHandle

+ (void)initialize {
    BDPPackageStreamingFileHandleSerialQueue = dispatch_queue_create("com.bytedance.timor.package.streamingFileHandle.global.serialQueue", NULL);
}
//通过下载上下文可以创建一个流式包 fileHandle
- (instancetype)initWithDownloadContext:(BDPPackageDownloadContext *)downloadContext {
    if (self = [super init]) {
        self.downloadContext = downloadContext;
        self.serialQueue = dispatch_queue_create("com.bytedance.timor.package.streamingFileHandle.serialQueue", NULL);
        dispatch_queue_set_specific(self.serialQueue, (__bridge void *)self, (__bridge void *)self.serialQueue, NULL);
        self.readDataTasksLock = [[NSRecursiveLock alloc] init];
        self.syncApiLock = dispatch_semaphore_create(1);
        self.createTime = [[NSDate date] timeIntervalSince1970];
        self.usedCacheMeta = NO;
    }
    return self;
}
//如果文件已经下载，可以通过这个API创建fileHandle
- (instancetype)initAfterDownloadedWithPackageContext:(BDPPackageContext *)packageContext {
    BDPPackageDownloadContext *downloadContext = [[BDPPackageDownloadContext alloc] initAfterDownloadedWithPackageContext:packageContext];
    BDPPackageStreamingFileHandle *handle = [self initWithDownloadContext:downloadContext];
    [handle readHeaderInfoWithLastFileOffset:downloadContext.lastFileOffset];
    return handle;
}

#pragma mark - Public

- (void)cancelAllReadDataCompletionBlks {
    [self.readDataTasksLock lock];
    [self.readDataTasksQueue emptyQueue];
    [self.readDataTasksSet removeAllObjects];
    [self.checkFileInfoBlkQueue emptyQueue];
    [self.readDataTasksLock unlock];
    NSArray<dispatch_semaphore_t> *syncSemaphores = nil;
    LOCK(self.syncApiLock, { syncSemaphores = [self.syncApiSemaphores copy]; });
    for (dispatch_semaphore_t lock in syncSemaphores) {
        dispatch_semaphore_signal(lock);
    }
}

#pragma mark - Helper

- (void)executeSync:(BOOL)sync inSelfQueueOfBlk:(dispatch_block_t)blk {
    if (!blk) {
        return;
    }
    if (dispatch_get_specific((__bridge void *)self)) {
        blk();
    } else {
        if (sync) {
            dispatch_sync(self.serialQueue, blk);
        } else {
            dispatch_async(self.serialQueue, blk);
        }
    }
}

#pragma mark - Property

- (BDPPackageContext *)packageContext {
    return self.downloadContext.packageContext;
}

- (BDPPkgFileLoadStatus)loadStatus {
    return self.downloadContext.loadStatus;
}

- (void)setLoadStatus:(BDPPkgFileLoadStatus)loadStatus {
    self.downloadContext.loadStatus = loadStatus;
}

- (BDPPkgFileLoadStatus)createLoadStatus {
    return self.downloadContext.createLoadStatus;
}

- (uint64_t)lastFileOffset {
    return self.downloadContext.lastFileOffset;
}

- (NSString *)pkgPath {
    BDPPackageContext *packageContext = self.packageContext;
    NSString *packagePath = [BDPPackageLocalManager localPackagePathForContext:packageContext];
    return packagePath;
}

#pragma mark LazyLoading

- (NSMutableSet<NSString *> *)loadedFileNames {
    if (!_loadedFileNames) {
        _loadedFileNames = [[NSMutableSet<NSString *> alloc] init];
    }
    return _loadedFileNames;
}

- (NSMutableArray<NSDictionary *> *)fileRecords {
    if (!_fileRecords) {
        _fileRecords = [[NSMutableArray<NSDictionary *> alloc] initWithCapacity:MAX_FILE_RECORD_COUNT];
    }
    return _fileRecords;
}

- (NSMutableSet<dispatch_semaphore_t> *)syncApiSemaphores {
    if (!_syncApiSemaphores) {
        _syncApiSemaphores = [[NSMutableSet<dispatch_semaphore_t> alloc] init];
    }
    return _syncApiSemaphores;
}

- (BDPPkgFileBasicModel *)basic {
    BDPPackageDownloadContext *downloadContext = self.downloadContext;
    @synchronized (self) {
        if (!_basic) {
            BDPPackageContext *packageContext = downloadContext.packageContext;
    //        BDPUniqueID *uniqueID = [BDPUniqueID uniqueIDWithAppID:packageContext.identifier versionType:packageContext.versionType appType:packageContext.appType];
            // TODO: P1 yinyuan 确认这里直接使用外部传入的 uniqueID 与原始的 identifier 作为 appID 构造 uniqueID 的意图是否匹配
            BDPPkgFileBasicModel *basic = [BDPPkgFileBasicModel basicModelWithUniqueId:packageContext.uniqueID
                                                                                   md5:packageContext.md5
                                                                               pkgName:packageContext.packageName
                                                                              readType:packageContext.readType
                                                                           requestURLs:packageContext.urls
                                                                               version:nil
                                                                           versionCode:0
                                                                             debugMode:NO];
            
            id<BDPPackageInfoManagerProtocol> packageInfoManager = BDPGetResolvedModule(BDPPackageModuleProtocol, packageContext.uniqueID.appType).packageInfoManager;
            basic.isFirstOpen = [packageInfoManager queryCountOfPkgInfoWithUniqueID:basic.uniqueID readType:BDPPkgFileReadTypeNormal] <= 0;
            NSArray<NSNumber *> *readTypes = [packageInfoManager queryPkgReadTypeOfUniqueID:basic.uniqueID pkgName:basic.pkgName];
            if (readTypes.count >= 2) {
                basic.dbReadType = readTypes[0].intValue <= 0 ? basic.readType : readTypes[0].intValue;
                basic.firstReadType = readTypes[1].intValue <= 0 ? basic.readType : readTypes[1].intValue;
            }
            if([[BDPSubPackageManager sharedManager] enableSubPackageWithUniqueId:packageContext.uniqueID]&&
               packageContext.metaSubPackage) {
                //将 packageContext 中的 path 相关信息返回
                id<AppMetaSubPackageProtocol> metaSubPackage = packageContext.metaSubPackage;
                basic.pagePath = (metaSubPackage == nil || metaSubPackage.isMainPackage) ? nil : metaSubPackage.path;
            }
            _basic = basic;
        }
    }
    _basic.isDownloadRange = downloadContext.isDownloadRange; // 断点续传
    _basic.isReusePreload = downloadContext.isReusePreload; // 复用预下载任务
    return _basic;
}

@end

#pragma clang diagnostic pop
