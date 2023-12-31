//
//  HMDCrashAppGroupURL.m
//  Pods
//
//  Created by xuminghao.eric on 2020/8/17.
//

#import "HMDCrashAppGroupURL.h"
#import "HMDInjectedInfo.h"
#import "HMDFileTool.h"

@implementation HMDCrashAppGroupURL

+ (void)createFileOrDirectoryAtURLIfNeeded:(NSURL *)url createDir:(BOOL)createDir{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    BOOL isExist = [fileManager fileExistsAtPath:url.resourceSpecifier isDirectory:&isDirectory];
    if (isExist && (isDirectory != createDir)) {
        [fileManager removeItemAtPath:url.resourceSpecifier error:nil];
        isExist = NO;
    }
    if (!isExist) {
        if (createDir) {
            hmdCheckAndCreateDirectory(url.resourceSpecifier);
        } else {
            [fileManager createFileAtPath:url.resourceSpecifier contents:nil attributes:nil];
        }
    }
}

+ (NSURL *)appGroupRootURL{
    static NSURL *appGroupRootURL;
    static dispatch_once_t onceToken;
    if ([HMDInjectedInfo defaultInfo].appGroupID) {
        dispatch_once(&onceToken, ^{
            appGroupRootURL = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[HMDInjectedInfo defaultInfo].appGroupID] copy];
        });
    }
    return appGroupRootURL;
}

+ (NSURL *)appGroupHeimdallrRootURL{
    static NSURL *appGroupHeimdallrRootURL;
    static dispatch_once_t onceToken;
    if ([HMDCrashAppGroupURL appGroupRootURL]) {
        dispatch_once(&onceToken, ^{
            appGroupHeimdallrRootURL = [[[HMDCrashAppGroupURL appGroupRootURL] URLByAppendingPathComponent:@"Library/Caches/Heimdallr"] copy];
            
            [HMDCrashAppGroupURL createFileOrDirectoryAtURLIfNeeded:appGroupHeimdallrRootURL createDir:YES];
        });
    }
    return appGroupHeimdallrRootURL;
}

+ (NSURL *)appGroupCrashFilesURL{
    static NSURL *appGroupCrashFilesURL;
    static dispatch_once_t onceToken;
    if ([HMDCrashAppGroupURL appGroupHeimdallrRootURL]) {
        dispatch_once(&onceToken, ^{
            appGroupCrashFilesURL = [[[HMDCrashAppGroupURL appGroupHeimdallrRootURL] URLByAppendingPathComponent:@"Crash"] copy];
            
            [HMDCrashAppGroupURL createFileOrDirectoryAtURLIfNeeded:appGroupCrashFilesURL createDir:YES];
        });
    }
    return appGroupCrashFilesURL;
}

+ (NSURL *)appGroupCrashSettingsURL{
    static NSURL *appGroupCrashSettingsURL;
    static dispatch_once_t onceToken;
    if ([HMDCrashAppGroupURL appGroupHeimdallrRootURL]) {
        dispatch_once(&onceToken, ^{
            appGroupCrashSettingsURL = [[[HMDCrashAppGroupURL appGroupHeimdallrRootURL] URLByAppendingPathComponent:@"crash_settings.json"] copy];
            
            [HMDCrashAppGroupURL createFileOrDirectoryAtURLIfNeeded:appGroupCrashSettingsURL createDir:NO];
        });
    }
    return appGroupCrashSettingsURL;
}

@end
