//
//  HMDZipArchiveService.m
//  Heimdallr
//
//  Created by Nickyo on 2023/3/30.
//

#import "HMDZipArchiveService.h"
#if RANGERSAPM
#import "HMDZipArchive.h"
#else
#import <SSZipArchive/SSZipArchive.h>
#endif

@implementation HMDZipArchiveService

+ (BOOL)createZipFileAtPath:(NSString *)path withFilesAtPaths:(NSArray<NSString *> *)paths {
    return [[self zipArchive] createZipFileAtPath:path withFilesAtPaths:paths];
}

+ (BOOL)createZipFileAtPath:(NSString *)path withContentsOfDirectory:(NSString *)directoryPath {
    return [[self zipArchive] createZipFileAtPath:path withContentsOfDirectory:directoryPath];
}

+ (Class<HMDZipArchiveProtocol>)zipArchive {
#if RANGERSAPM
    return [HMDZipArchive class];
#else
    return [SSZipArchive class];
#endif
}

@end
