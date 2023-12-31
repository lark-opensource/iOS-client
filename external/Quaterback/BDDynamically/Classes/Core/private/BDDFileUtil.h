//
//  BDDFileeUtil.h
//  BDDynamically
//
//  Created by hopo on 2019/11/3.
//

#import <Foundation/Foundation.h>
#import "BDDYCModelKey.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *DYCGetCurrentLibraryDirectory()
{
    static NSString *libDir = nil;
    if (!libDir) {
        libDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    }
    return libDir;
}

static NSString *DYCGetRootDirectory()
{
    return [DYCGetCurrentLibraryDirectory() stringByAppendingPathComponent:BDDYC_MODULE_ROOT_DIR];
}

// 历史补丁列表文件
static NSString *DYCModuleHistoryMainDirectory()
{
    NSString *libDir  = DYCGetCurrentLibraryDirectory();
    NSString *mainDir = [libDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/_history", BDDYC_MODULE_ROOT_DIR]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:mainDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:mainDir withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return mainDir;
}

// 历史补丁文件目录
static NSString *DYCModuleAlphaMainDirectory()
{
    NSString *libDir  = DYCGetCurrentLibraryDirectory();
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *mainDir = [libDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@/_alpha", BDDYC_MODULE_ROOT_DIR, version]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:mainDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:mainDir withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return mainDir;
}

static NSString *DYCModuleDirectory(NSString *moduleName) {
    NSString *mainDir = DYCModuleAlphaMainDirectory();
    NSString *moduleDir = [mainDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", moduleName]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:moduleDir]) {
        NSError *err = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:moduleDir withIntermediateDirectories:YES attributes:nil error:&err];
        if (err) {
        }
    }
    return moduleDir;
}

NS_ASSUME_NONNULL_END
