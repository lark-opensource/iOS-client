//
//  BDPStorageModule.m
//  Timor
//
//  Created by houjihu on 2020/3/24.
//

#import "BDPStorageModule.h"
#import "BDPSandboxEntity.h"
#import "BDPLocalFileManager.h"
#import <OPFoundation/BDPCommonManager.h>
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/BDPModuleManager.h>
#import <ECOInfra/BDPLog.h>

@interface BDPStorageModule ()

@property (nonatomic, strong) NSMapTable <BDPUniqueID *, id<BDPSandboxProtocol>> *sandboxMap;
@property (nonatomic, strong) NSRecursiveLock *sandboxMapLock;

@end

@implementation BDPStorageModule

- (instancetype)init {
    self = [super init];
    if (self) {
        _sandboxMap = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory capacity:100];
        _sandboxMapLock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

#pragma mark - BDPSandboxProtocol

- (id<BDPSandboxProtocol>)createSandboxWithUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName {
    return [[BDPSandboxEntity alloc] initWithUniqueID:uniqueID pkgName:pkgName];
}

- (id<BDPMinimalSandboxProtocol>)minimalSandboxWithUniqueID:(BDPUniqueID *)uniqueID {
    return [[BDPMinimalSandboxEntity alloc] initWithUniqueID:uniqueID];
}

- (id<BDPSandboxProtocol>)sandboxForUniqueId:(OPAppUniqueID *)uniqueId {
    id<BDPSandboxProtocol> sandbox = nil;

    if (uniqueId.appType == OPAppTypeGadget) {
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueId];
        sandbox = common.sandbox;
    }

    if (uniqueId.appType == OPAppTypeBlock || uniqueId.appType == OPAppTypeThirdNativeApp) {
        id<OPContainerProtocol> container = [OPApplicationService.current getContainerWithUniuqeID:uniqueId];
        sandbox = container.sandbox;
    }
    
    if (uniqueId.appType == OPAppTypeWebApp) {
        id<BDPSandboxProtocol> cacheSandbox = [self getSandboxByUniqueID:uniqueId];
        if (!cacheSandbox) {
            cacheSandbox = [self createSandboxWithUniqueID:uniqueId pkgName:@""];
            [self bindSandbox:cacheSandbox uniqueID:uniqueId];
        }
        sandbox = cacheSandbox;
    }

    /// 兜底逻辑，凡是拿不到 sandbox 的，统一尝试从 BDPCommon 取一次。
    /// 历史逻辑上，BDPCommon 是出现最早的小程序形态 model，较老的逻辑会依赖此假设，代码迁移前的逻辑也依赖此假设。
    if (!sandbox) {
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueId];
        sandbox = common.sandbox;
        BDPLogWarn(@"get unadapt sandbox with app_id: %@, appType: %@, hasSandbox: %@",
                   uniqueId.appID,
                   OPAppTypeToString(uniqueId.appType),
                   @(sandbox != nil));
    }
    return sandbox;
}

- (nullable id<BDPSandboxProtocol>)getSandboxByUniqueID:(nullable BDPUniqueID *)uniqueID {
    if (uniqueID) {
        id<BDPSandboxProtocol> sandbox;
        [_sandboxMapLock lock];
        sandbox = [self.sandboxMap objectForKey:uniqueID];
        [_sandboxMapLock unlock];
        return sandbox;
    }
    
    return nil;
}

- (void)bindSandbox:(nullable id<BDPSandboxProtocol>)sandbox uniqueID:(nullable BDPUniqueID *)uniqueID {
    if (sandbox && uniqueID) {
        [_sandboxMapLock lock];
        [self.sandboxMap setObject:sandbox forKey:uniqueID];
        [_sandboxMapLock unlock];
    }
}

- (void)restSandboxEntityMap {
    [_sandboxMapLock lock];
    [self.sandboxMap removeAllObjects];
    [_sandboxMapLock unlock];
}

#pragma mark - BDPLocalFileManagerProtocol

- (id<BDPLocalFileManagerProtocol>)sharedLocalFileManager {
    return [BDPLocalFileManager sharedInstanceForType:self.moduleManager.type];
}

/// 用于退出登陆时，清理跟所有应用类型文件目录相关的单例对象，便于再次登录时重新初始化
- (void)clearAllSharedLocalFileManagers {
    [BDPLocalFileManager clearAllSharedInstances];
}

/// 用于退出登陆时，清理跟小程序文件目录相关的单例对象，便于再次登录时重新初始化
- (void)clearSharedLocalFileManagerForType:(BDPType)type {
    [BDPLocalFileManager clearSharedInstanceForType:type];
}

#pragma mark Folder Name

//@"__dev__"
- (NSString *)JSLibFolderName {
    return [BDPLocalFileManager JSLibFolderName];
}

//@"__dev__/h5jssdk"
- (NSString *)H5JSLibFolderName {
    return [BDPLocalFileManager H5JSLibFolderName];
}

//@"offline"
- (NSString *)offlineFolderName {
    return [BDPLocalFileManager offlineFolderName];
}

- (BOOL)hasAccessRightsForPath:(NSString *)path onSandbox:(id<BDPSandboxProtocol> )sandbox {
    return [BDPLocalFileManager hasAccessRightsForPath:path onSandbox:sandbox];
}

#pragma mark ttfile支持
/** 生成随机file:路径 */
- (NSString *)generateRandomFilePathWithType:(BDPFolderPathType)type
                                     sandbox:(id<BDPMinimalSandboxProtocol> )sandbox
                                   extension:(NSString *)extension
                               addFileScheme:(BOOL)addFileScheme {
    return [BDPLocalFileManager generateRandomFilePathWithType:type sandbox:sandbox extension:extension addFileScheme:addFileScheme];
}

@end
