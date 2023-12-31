//
//  HMDCDGenerator.m
//  Heimdallr
//
//  Created by maniackk on 2020/11/4.
//

#import <stdatomic.h>
#import <sys/utsname.h>

#import "HMDMacro.h"
#import "HMDCDConfig.h"
#import "HMDCDUploader.h"
#import "HMDCDSaveCore.h"
#import "HMDCDGenerator.h"
#import "HMDALogProtocol.h"
#import "Heimdallr+Private.h"
#import "HMDCDConfig+Private.h"
#import "HMDCDGenerator+Private.h"

#define CD_500MB (1024*1024*500)

@implementation HMDCDGenerator

@synthesize uploader = _uploader;

+ (instancetype)sharedGenerator {
    static HMDCDGenerator *generator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        generator = HMDCDGenerator.new;
    });
    return generator;
}

- (instancetype)init {
    if(self = [super init]) {
        _uploader = HMDCDUploader.new;
    }
    return self;
}

#pragma mark - Upload

- (void)triggerUpload {
    [_uploader zipAndUploadCoreDump];
}

#pragma mark - HeimdallrModule Protocol Method

- (BOOL)needSyncStart {
    return NO;
}

- (void)start {
    [super start];
    
    if(!is_support_coredump()) return;
    if(![self diskSpaceAvailable]) return;
    
    hmd_cd_set_isOpen(true);
}

- (void)stop {
    [super stop];
    hmd_cd_set_isOpen(false);
}

static atomic_bool coredump_config_applied = false;

- (void)prepareCoreDump {
    if(coredump_config_applied) return;
    // 其实是有线程竞争的可能性，不过就算竞争，默认参数也没有那么多问题
    
    hmd_cd_set_basePath(_uploader.coredumpPath.UTF8String);
    hmd_cd_set_maxCDFileSizeMB(HMD_CD_DEFAULT_maxCDFileSizeMB);
    hmd_cd_set_minFreeDiskUsageMB(HMD_CD_DEFAULT_minFreeDiskUsageMB);
    hmd_cd_set_dumpNSException(HMD_CD_DEFAULT_dumpNSException);
    hmd_cd_set_dumpCPPException(HMD_CD_DEFAULT_dumpCPPException);
    
    hmd_cd_markReady();
}

- (void)updateConfig:(HMDModuleConfig *)config {
    [super updateConfig:config];
    if(![config isKindOfClass:HMDCDConfig.class]) DEBUG_RETURN_NONE;
    HMDCDConfig *coredumpConfig = (HMDCDConfig *)config;
    
    coredump_config_applied = true;
    _uploader.maxCDZipFileSizeMB = coredumpConfig.maxCDZipFileSizeMB;
    hmd_cd_set_basePath(_uploader.coredumpPath.UTF8String);
    hmd_cd_set_maxCDFileSizeMB(coredumpConfig.maxCDFileSizeMB);
    hmd_cd_set_minFreeDiskUsageMB(coredumpConfig.minFreeDiskUsageMB);
    hmd_cd_set_dumpNSException(coredumpConfig.dumpNSException);
    hmd_cd_set_dumpCPPException(coredumpConfig.dumpCPPException);
    
    hmd_cd_markReady();
}

static BOOL is_support_coredump(void) {
    if (@available(iOS 10, *)) {}
    else { return NO; }
    
#if (defined(__arm64__) && defined(TARGET_OS_IPHONE))
    return YES;
#else
    return NO;
#endif
}

- (BOOL)diskSpaceAvailable {
    return folderSizeAtPath(_uploader.coredumpRootPath) < CD_500MB;
}

static long long folderSizeAtPath(NSString* folderPath){
    NSFileManager *manager = NSFileManager.defaultManager;
    if (![manager fileExistsAtPath:folderPath]) return 0;
    
    NSEnumerator *childFilesEnumerator = [manager subpathsAtPath:folderPath].objectEnumerator;
    
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = childFilesEnumerator.nextObject) != nil) {
        
        NSString *fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        
        BOOL isDirectory; BOOL isExist;
        isExist = [manager fileExistsAtPath:fileAbsolutePath isDirectory:&isDirectory];
        
        if(!isExist || isDirectory) continue;
        
        folderSize += [manager attributesOfItemAtPath:fileAbsolutePath error:nil].fileSize;
    }
    
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"coredump folder size: %lld", folderSize);
    return folderSize;
}

@end

void HMDCoreDump_triggerUpload(void) {
    [HMDCDGenerator.sharedGenerator triggerUpload];
}
