//
//  HMDCrashUploader.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/22.
//

#import "HMDCrashUploader.h"
#if EMBED
#import "HMDEmbedCrashUploader.h"
#else
#import "HMDStandardCrashUploader.h"
#endif /* EMBED */

@implementation HMDCrashUploader

+ (id<HMDCrashUploader>)uploaderWithPath:(NSString *)path {
#if EMBED
    return [[HMDEmbedCrashUploader alloc] initWithPath:path];
#else
    return [[HMDStandardCrashUploader alloc] initWithPath:path];
#endif /* EMBED */
}

@end
