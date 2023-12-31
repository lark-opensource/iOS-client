//
//  HMDBinaryImage.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/25.
//
#include <stdatomic.h>

#import "HMDBinaryImage.h"
#import "HMDCompactUnwind.hpp"
#import "pthread_extended.h"
#import "HMDDeviceTool.h"

static NSArray *sharedBinaryImages;
static NSString *sharedBinaryImagesLog;
static atomic_uint sharedBinaryImagesVersion;

static pthread_rwlock_t lock = PTHREAD_RWLOCK_INITIALIZER;


@implementation HMDBinaryImage
+ (NSArray<HMDBinaryImage *> *)linkedBinaryImages {
    NSMutableArray<HMDBinaryImage *> *infoArray = [NSMutableArray array];
    hmd_enumerate_image_list_using_block(^(hmd_async_image_t *image, int index, bool *stop) {
        HMDBinaryImage *binaryImage = [self binaryImageWithMachoImage:&image->macho_image];
        if (binaryImage) {
            [infoArray addObject:binaryImage];
        }
    });
    return infoArray;
}

+ (NSSet<HMDBinaryImage *> * _Nullable)findSharedCacheImages:(NSArray<HMDBinaryImage *> * _Nonnull)images {
    if(images == nil) return nil;
    
    NSMutableSet<NSNumber *> *duplicatedSlides = [[NSMutableSet alloc] init];
    NSMutableSet<NSNumber *> *existingSlides = [[NSMutableSet alloc] init];
    
    [images enumerateObjectsUsingBlock:^(HMDBinaryImage * _Nonnull eachImage, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *eachSlide = @(eachImage.vm_slide);
        if([existingSlides containsObject:eachSlide]) [duplicatedSlides addObject:eachSlide];
        else [existingSlides addObject:eachSlide];
    }];
    
    NSMutableSet<HMDBinaryImage *> *sharedCaches = [NSMutableSet set];
    
    [images enumerateObjectsUsingBlock:^(HMDBinaryImage * _Nonnull eachImage, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *eachSlide = @(eachImage.vm_slide);
        if([duplicatedSlides containsObject:eachSlide])
            [sharedCaches addObject:eachImage];
    }];
    
    return sharedCaches;
}

+ (HMDBinaryImage *)binaryImageWithMachoImage:(hmd_async_macho_t *)macho_image {
    HMDBinaryImage *binaryImage = [[HMDBinaryImage alloc] init];
    binaryImage.address = macho_image->header_addr;
    binaryImage.vm_slide = macho_image->vmaddr_slide;
    binaryImage.textSize = macho_image->text_segment.size;
    BOOL isExecutable = hmd_async_macho_is_executable(macho_image)?YES:NO;
    binaryImage.isExecutable = isExecutable;
    binaryImage.isFromAPP = macho_image->is_app_image;
    binaryImage.uuid = [NSString stringWithUTF8String:macho_image->uuid];
    binaryImage.cpuType = hmd_async_macho_cpu_type(macho_image);
    binaryImage.cpuSubType = hmd_async_macho_cpu_subtype(macho_image);
    if (macho_image->name != NULL) {
        NSString *path = [NSString stringWithUTF8String:macho_image->name];
        if (path.length > 0) {
            binaryImage.path = path;
            binaryImage.name = [path lastPathComponent];
        }
    }
    return binaryImage;
}

- (BOOL)isEqual:(id)object {
    if([object isKindOfClass:HMDBinaryImage.class]) {
        HMDBinaryImage *thisClassObject = object;
        if(self.address == thisClassObject.address) return YES;
    }
    return NO;
}

- (NSUInteger)hash {
    return self.address;
}

#pragma mark fast api

+ (void)updateSharedLinkedBinaryImagesIfNeed {
    
    hmd_setup_shared_image_list_if_need();
    
    if (sharedBinaryImagesVersion < hmd_async_share_image_list_version()) {
        pthread_rwlock_wrlock(&lock);
        NSMutableArray<HMDBinaryImage *> *infoArray = [NSMutableArray array];
        hmd_enumerate_image_list_using_block(^(hmd_async_image_t *image, int index, bool *stop) {
            HMDBinaryImage *binaryImage = [self binaryImageWithMachoImage:&image->macho_image];
            if (binaryImage) {
                [infoArray addObject:binaryImage];
            }
        });
        sharedBinaryImagesVersion = hmd_async_share_image_list_version();
        sharedBinaryImages = infoArray;
        [HMDBinaryImage updateSharedBinaryImagesLogStrNoLock];
        pthread_rwlock_unlock(&lock);
    }
}

+ (void)enumerateImagesUsingBlock:(HMDBinaryImageBlock)block {
    [HMDBinaryImage updateSharedLinkedBinaryImagesIfNeed];
    pthread_rwlock_rdlock(&lock);
    if(sharedBinaryImages == nil) {
        pthread_rwlock_unlock(&lock);
        return;
    }
    
    for (HMDBinaryImage * imageInfo in sharedBinaryImages) {
        if (block) {
            @autoreleasepool {
                block(imageInfo);
            }
        }
    }
    pthread_rwlock_unlock(&lock);
}

+ (NSSet<HMDBinaryImage *> * _Nullable)findSharedCacheImages {
    pthread_rwlock_rdlock(&lock);
    if(sharedBinaryImages == nil) {
        pthread_rwlock_unlock(&lock);
        return nil;
    }
    
    NSMutableSet<NSNumber *> *duplicatedSlides = [[NSMutableSet alloc] init];
    NSMutableSet<NSNumber *> *existingSlides = [[NSMutableSet alloc] init];
    
    [sharedBinaryImages enumerateObjectsUsingBlock:^(HMDBinaryImage * _Nonnull eachImage, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *eachSlide = @(eachImage.vm_slide);
        if([existingSlides containsObject:eachSlide]) [duplicatedSlides addObject:eachSlide];
        else [existingSlides addObject:eachSlide];
    }];
    
    NSMutableSet<HMDBinaryImage *> *sharedCaches = [NSMutableSet set];
    
    [sharedBinaryImages enumerateObjectsUsingBlock:^(HMDBinaryImage * _Nonnull eachImage, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *eachSlide = @(eachImage.vm_slide);
        if([duplicatedSlides containsObject:eachSlide])
            [sharedCaches addObject:eachImage];
    }];
    pthread_rwlock_unlock(&lock);
    
    return sharedCaches;
}



- (NSString*) imageLogStringWithImageInfo
{
    if (!(_path && _name && _uuid)) {
        return nil;
    }
    char * _Nullable arch = hmd_cpu_arch(_cpuType, _cpuSubType, false);
    NSString *cpuType;
    if (arch != NULL) cpuType = [NSString stringWithUTF8String:arch];
    
    uintptr_t imageAddr = (uintptr_t)_address;
    uintptr_t imageSize = (uintptr_t)_textSize;
    NSString* path = _path;
    NSString* name = _name;
    NSString* uuid = _uuid;
    NSString* imagePrefix = _isExecutable ? @"+" : @" ";

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
    [HMDBinaryImage updateSharedLinkedBinaryImagesIfNeed];
    NSMutableString* imagesLogStr = [NSMutableString stringWithString:@"\nBinary Images:\n"];
    pthread_rwlock_rdlock(&lock);
    if (sharedBinaryImages) {
        for (HMDBinaryImage * imageInfo in sharedBinaryImages) {
            @autoreleasepool {
                NSString *imageLog = [imageInfo imageLogStringWithImageInfo];
                if (imageLog.length > 0) {
                    [imagesLogStr appendString:imageLog];
                }
            }
        }
    }
    pthread_rwlock_unlock(&lock);
    return imagesLogStr;
}

+ (void)updateSharedBinaryImagesLogStrNoLock {
    NSMutableString* imagesLogStr = [NSMutableString stringWithString:@"\nBinary Images:\n"];
    if (sharedBinaryImages) {
        for (HMDBinaryImage * imageInfo in sharedBinaryImages) {
            @autoreleasepool {
                NSString *imageLog = [imageInfo imageLogStringWithImageInfo];
                if (imageLog.length > 0) {
                    [imagesLogStr appendString:imageLog];
                }
            }
        }
    }
    sharedBinaryImagesLog = imagesLogStr;
}

+ (void)getSharedBinaryImagesLogStrUsingCallback:(HMDBinaryImageStrLogBlock)block {
    [HMDBinaryImage updateSharedLinkedBinaryImagesIfNeed];
    
    pthread_rwlock_rdlock(&lock);
    if (sharedBinaryImagesLog && block) {
        block(sharedBinaryImagesLog);
    }
    pthread_rwlock_unlock(&lock);
}

+ (NSString *)binaryImagesLogStrWithMustIncludeImagesNames:(NSMutableSet<NSString*>*)imageSet
                             includePossibleJailbreakImage:(BOOL)needJailbreakIncluded {
    NSSet<HMDBinaryImage *> *sharedCacheImages = [HMDBinaryImage findSharedCacheImages];
    
    NSMutableString* imagesLogStr = [NSMutableString stringWithString:@"\nBinary Images:\n"];
    pthread_rwlock_rdlock(&lock);
    if (sharedBinaryImages) {
        for (HMDBinaryImage * imageInfo in sharedBinaryImages) {
            @autoreleasepool {
                // 只输出堆栈中存在的image信息
                BOOL containsInImageSet = [imageSet containsObject:imageInfo.name];
                
                if(!containsInImageSet) {
                    if(!needJailbreakIncluded) continue;
                    if([sharedCacheImages containsObject:imageInfo]) continue;
                }
                
                NSString *imageLog = [imageInfo imageLogStringWithImageInfo];
                if (imageLog.length > 0) {
                    [imagesLogStr appendString:imageLog];
                }
            }
        }
    }
    pthread_rwlock_unlock(&lock);
    return imagesLogStr;
}

@end
