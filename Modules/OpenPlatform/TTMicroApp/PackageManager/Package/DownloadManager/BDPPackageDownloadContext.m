//
//  BDPPackageDownloadContext.m
//  Timor
//
//  Created by houjihu on 2020/7/7.
//

#import "BDPPackageDownloadContext.h"
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import <OPFoundation/NSError+BDPExtension.h>
#import "BDPPackageLocalManager.h"
#import <OPFoundation/BDPUniqueID.h>

#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/OPError.h>

@interface BDPPackageDownloadContext ()

/// 下载回调集合，用于合并重复下载请求
@property (nonatomic, strong, nullable, readwrite) NSMutableArray<BDPPackageDownloadResponseHandler *> *responseHandlers;

@end

@implementation BDPPackageDownloadContext

- (instancetype)initAfterDownloadedWithPackageContext:(BDPPackageContext *)packageContext {
    if (self = [super init]) {
        OPError *downloadTaskIDError;
        // TODO: yinyuan 确认 identifier 当做 appID 使用
        NSString *downloadTaskID = [BDPPackageDownloadContext taskIDWithUniqueID:packageContext.uniqueID packageName:packageContext.packageName error:&downloadTaskIDError];
        // 检查创建的下载任务的ID
        if (downloadTaskIDError) {
            CommonMonitorWithCodeIdentifierType(CommonMonitorCodePackage.pkg_download_failed, packageContext.uniqueID)
            .addTag(BDPTag.packageManager)
            .bdpTracing(packageContext.trace)
            .kv(kEventKey_load_type, BDPPkgFileReadTypeInfo(packageContext.readType))
            .kv(kEventKey_app_version, packageContext.version)
            .kv(kEventKey_package_name, packageContext.packageName)
            .setError(downloadTaskIDError)
            .flush();
        }
        self.taskID = downloadTaskID;
        self.packageContext = packageContext;
        // 创建fileHandle，以供持续写入下载数据
        NSError *aError;
        self.fileHandle = [BDPPackageLocalManager createFileHandleForContext:packageContext error:&aError];
        if (aError) {
            CommonMonitorWithCodeIdentifierType(CommonMonitorCodePackage.pkg_download_failed, packageContext.uniqueID)
            .addTag(BDPTag.packageManager)
            .bdpTracing(packageContext.trace)
            .kv(kEventKey_load_type, BDPPkgFileReadTypeInfo(packageContext.readType))
            .kv(kEventKey_app_version, packageContext.version)
            .kv(kEventKey_package_name, packageContext.packageName)
            .setError(aError)
            .flush();
        }
        [self.fileHandle seekToEndOfFile];
        self.lastFileOffset = self.fileHandle.offsetInFile;
        self.originalFileOffset = self.lastFileOffset;
        self.loadStatus = BDPPkgFileLoadStatusDownloaded;
        self.createLoadStatus = self.loadStatus;
        // isDownloadRange需要在重置文件操作后再执行。如果重置文件后，originalFileOffset会发生变化
        self.isDownloadRange = (self.originalFileOffset > 0);
    }
    return self;
}

- (void)addResponseHandler:(BDPPackageDownloadResponseHandler *)handler {
    [self.responseHandlers addObject:handler];
}

- (void)removeResponseHandler:(BDPPackageDownloadResponseHandler *)handler {
    [self.responseHandlers removeObject:handler];
}

- (NSMutableArray<BDPPackageDownloadResponseHandler *> *)responseHandlers {
    if (!_responseHandlers) {
        _responseHandlers = [[NSMutableArray alloc] init];
    }
    return _responseHandlers;
}

/// 计算标识下载任务的ID
+ (NSString *)taskIDWithUniqueID:(BDPUniqueID *)uniqueID packageName:(NSString *)packageName error:(OPError **)error {
    NSString *taskID;
    // TODO: yinyuan 确认 identifier 当做 appID 使用
    if (!uniqueID.isValid) {
        NSString *errorMessage = @"uniqueID is invalid";
        OPError *IDError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_download_invalid_params, errorMessage);
        if (error) {
            *error = IDError;
        }
        return nil;
    }
    if (BDPIsEmptyString(packageName)) {
        NSString *errorMessage = [NSString stringWithFormat:@"packageName is empty for ID(%@)", uniqueID];
        OPError *pkgNameError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_download_invalid_params, errorMessage);
        if (error) {
            *error = pkgNameError;
        }
        return nil;
    }
    if (uniqueID.appType == OPAppTypeBlock) {
        // 每个block实例对应不同的blockID，但他们可能共享一个task
        taskID = [NSString stringWithFormat:@"%@%@_%@", uniqueID.appID, uniqueID.identifier, packageName];
    } else {
        taskID = [NSString stringWithFormat:@"%@_%@", uniqueID.fullString, packageName];
    }
    return taskID;
}

@end
