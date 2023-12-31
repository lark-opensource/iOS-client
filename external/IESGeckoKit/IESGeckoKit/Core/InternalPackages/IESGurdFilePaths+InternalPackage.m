//
//  IESGurdFilePaths+InternalPackage.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/9/21.
//

#import "IESGurdFilePaths+InternalPackage.h"

static NSString * const kIESGurdInternalPackageConfigFileName = @"gecko_internal_packages";

@implementation IESGurdFilePaths (InternalPackage)

+ (NSString *)internalPackagesDirectory
{
    static NSString *internalPackagesDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *applicationSupportPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
        internalPackagesDirectory = [applicationSupportPath stringByAppendingPathComponent:@"gurd_internal_packages"];
    });
    return internalPackagesDirectory;
}

+ (NSString *)internalPackageMetaInfosPath
{
    return [[self internalPackagesDirectory] stringByAppendingPathComponent:@".internal_packages_meta"];
}

+ (NSString *)configFilePathWithBundleName:(NSString * _Nullable)bundleName
{
    NSBundle *bundle = [NSBundle mainBundle];
    if (bundleName.length > 0) {
        NSString *bundlePath = [bundle pathForResource:bundleName ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:bundlePath];
    }
    return [bundle pathForResource:kIESGurdInternalPackageConfigFileName ofType:@"json"];
}

+ (NSString *)bundlePathWithName:(NSString * _Nullable)bundleName
{
    if (bundleName.length == 0) {
        return [[NSBundle mainBundle] bundlePath];
    }
    return [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle"];
}

+ (NSString *)internalPackageDirectoryForAccessKey:(NSString *)accessKey
{
    return [[self internalPackagesDirectory] stringByAppendingPathComponent:accessKey];
}

+ (NSString *)internalRootDirectoryForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [[[self internalPackagesDirectory] stringByAppendingPathComponent:accessKey] stringByAppendingPathComponent:channel];
}

@end
