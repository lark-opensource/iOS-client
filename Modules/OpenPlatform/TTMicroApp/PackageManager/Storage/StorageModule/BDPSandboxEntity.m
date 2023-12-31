//
//  BDPSandboxEntity.m
//  Timor
//
//  Created by liubo on 2018/12/17.
//

#import "BDPSandboxEntity.h"
#import "BDPLocalFileManager.h"
#import <OPFoundation/UIImage+BDPExtension.h>
#import <ECOInfra/BDPFileSystemHelper.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <TTMicroApp/TTMicroApp-Swift.h>

#define TMA_LOCAL_STORAGE_NAME @"local_storage"
#define TMA_PRIVATE_STORAGE_NAME @"private_storage"

#pragma mark - BDPSandboxEntity

@interface BDPMinimalSandboxEntity ()
@property (nonatomic, strong) BDPUniqueID *uniqueID;
@end

#pragma mark - BDPMinimalSandboxEntity

@implementation BDPMinimalSandboxEntity

#pragma mark - Init

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID {
    if (self = [super init]) {
        _uniqueID = uniqueID;
        
        [self buildSandbox];
    }
    return self;
}

- (void)buildSandbox {
    // create userPath & tmpPath & privateTmpPath
    [[LSFileSystem main] createFolderIfNeedWithFolderPath:[self userPath]];
    [[LSFileSystem main] createFolderIfNeedWithFolderPath:[self tmpPath]];
    [[LSFileSystem main] createFolderIfNeedWithFolderPath:[self privateTmpPath]];
}

#pragma mark - Interface

- (NSString *)tmpPath {
    return [[[self localFileManager] appTempPathWithUniqueID:self.uniqueID] stringByAppendingString:@"/"];
}

- (NSString *)userPath {
    return [[[self localFileManager] appSandboxPathWithUniqueID:self.uniqueID] stringByAppendingString:@"/"];
}

- (NSString *)privateTmpPath {
    return [[self localFileManager] appPrivateTmpPathWithUniqueID:self.uniqueID];
}

#pragma mark - Helper

- (BDPLocalFileManager *)localFileManager {
    return [BDPLocalFileManager sharedInstanceForType:self.uniqueID.appType];
}

@end

#pragma mark - BDPSandboxEntity

@interface BDPSandboxEntity ()

@property (nonatomic, copy) NSString *pkgName;
@property (nonatomic, strong, readwrite) TMAKVStorage *localStorage;
@property (nonatomic, strong, readwrite) TMAKVStorage *privateStorage;

@end

@implementation BDPSandboxEntity

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName {
    if (self = [super initWithUniqueID:uniqueID]) {
        _pkgName = pkgName;
        [self createStorageDB];
    }
    return self;
}

- (NSString *)rootPath {
    return [[[self localFileManager] appPkgDirPathWithUniqueID:self.uniqueID name:self.pkgName] stringByAppendingString:@"/"];
}

- (void)clearTmpPath {
    [[LSFileSystem main] removeItemAtPath:[NSURL fileURLWithPath:[self tmpPath] isDirectory:YES].path error:nil];
    NSError *error = nil;
    BOOL isSuccess = [[LSFileSystem main] createDirectoryAtPath:[NSURL fileURLWithPath:[self tmpPath] isDirectory:YES].path withIntermediateDirectories:YES attributes:nil error:&error];
    BDPMonitorWithName(kEventName_create_tmp_dir_result, nil)
    .kv(@"isSuccess", isSuccess)
    .setError(error)
    .flush();
}

- (void)clearPrivateTmpPath {
    [[LSFileSystem main] removeItemAtPath:[NSURL fileURLWithPath:[self privateTmpPath] isDirectory:YES].path error:nil];
    [[LSFileSystem main] createDirectoryAtPath:[NSURL fileURLWithPath:[self privateTmpPath] isDirectory:YES].path withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)createStorageDB {
    //userStorage.db
    TMAKVDatabase *db = [[TMAKVDatabase alloc] initWithDBWithPath:[[self localFileManager] appStorageFilePathWithUniqueID:self.uniqueID]];
    self.localStorage = [db storageForName:TMA_LOCAL_STORAGE_NAME];
    self.privateStorage = [db storageForName:TMA_PRIVATE_STORAGE_NAME];
}

@end
