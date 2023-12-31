//
//  HMDImageLog.m
//  Heimdallr
//
//  Created by 谢俊逸 on 12/3/2018.
//

#import "HMDImageLog.h"
#import "HMDLog.h"
#import "HMDInfo.h"
#import "HMDDeviceTool.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDBinaryImage.h"

@implementation HMDImageLog

+ (NSString*) imageLogStringWithImageInfo:(HMDBinaryImage *)info
{
    if (!(info && info.path && info.name && info.uuid)) {
        return nil;
    }
    char * _Nullable arch = hmd_cpu_arch(info.cpuType, info.cpuSubType, false);
    NSString *cpuType;
    if (arch != NULL) cpuType = [NSString stringWithUTF8String:arch];
    
    uintptr_t imageAddr = (uintptr_t)info.address;
    uintptr_t imageSize = (uintptr_t)info.textSize;
    NSString* path = info.path;
    NSString* name = info.name;
    NSString* uuid = info.uuid;
    NSString* imagePrefix = info.isExecutable ? @"+" : @" ";

    NSString *str = [NSString stringWithFormat:@"%#10lx - %#10lx %@%@ %@ <%@> %@\n",
     imageAddr,
     imageAddr + imageSize - 1,
     imagePrefix,
     name,
     cpuType,
     uuid,
     path];
    
    return str;
}

+ (NSString *)binaryImagesLogStr {
    NSArray<HMDBinaryImage *> *images = [HMDBinaryImage linkedBinaryImages];
    NSMutableString* imagesLogStr = [NSMutableString stringWithString:@"\nBinary Images:\n"];
    if (images) {
        for (HMDBinaryImage * imageInfo in images) {
            @autoreleasepool {
                NSString *imageLog = [HMDImageLog imageLogStringWithImageInfo:imageInfo];
                if (imageLog.length > 0) {
                    [imagesLogStr appendString:imageLog];
                }
            }
        }
    }
    return imagesLogStr;
}

+ (NSString *)binaryImagesLogStrWithMustIncludeImagesNames:(NSMutableSet<NSString*>*)imageSet
                             includePossibleJailbreakImage:(BOOL)needJailbreakIncluded {
    NSArray<HMDBinaryImage *> *images = [HMDBinaryImage linkedBinaryImages];
    NSSet<HMDBinaryImage *> *sharedCacheImages = [HMDBinaryImage findSharedCacheImages:images];
    
    NSMutableString* imagesLogStr = [NSMutableString stringWithString:@"\nBinary Images:\n"];
    if (images) {
        for (HMDBinaryImage * imageInfo in images) {
            @autoreleasepool {
                // 只输出堆栈中存在的image信息
                BOOL containsInImageSet = [imageSet containsObject:imageInfo.name];
                
                if(!containsInImageSet) {
                    if(!needJailbreakIncluded) continue;
                    if([sharedCacheImages containsObject:imageInfo]) continue;
                }
                
                NSString *imageLog = [HMDImageLog imageLogStringWithImageInfo:imageInfo];
                if (imageLog.length > 0) {
                    [imagesLogStr appendString:imageLog];
                }
            }
        }
    }
    return imagesLogStr;
}

@end
