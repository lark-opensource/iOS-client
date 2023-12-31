//
//  BDJTPageInPreloader.m
//  BDAsyncRenderKit
//
//  Created by bytedance on 2022/5/6.
//

#import "BDJTPageInPreloader.h"

#include <sys/kdebug_signpost.h>
#include <objc/message.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <stdatomic.h>
#include <dlfcn.h>

#import <ByteDanceKit/ByteDanceKit.h>

#ifndef DEBUG_ELSE
#ifdef DEBUG
#define DEBUG_ELSE else __builtin_trap();
#else
#define DEBUG_ELSE
#endif
#endif

static bool _bdjt_swizzle_instance_method(Class cls, SEL originalSelector, SEL swizzledSelector) {
    Method originMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    if (originMethod && swizzledMethod) {
        IMP originIMP = method_getImplementation(originMethod);
        IMP swizzledIMP = method_getImplementation(swizzledMethod);
        if (originIMP != NULL && swizzledIMP != NULL) {
            const char *originMethodType = method_getTypeEncoding(originMethod);
            const char *swizzledMethodType = method_getTypeEncoding(swizzledMethod);
            if(originMethodType && swizzledMethodType) {
                if (strcmp(originMethodType, swizzledMethodType) == 0) {
                    class_replaceMethod(cls, swizzledSelector, originIMP, originMethodType);
                    class_replaceMethod(cls, originalSelector, swizzledIMP, originMethodType);
                    return true;
                } DEBUG_ELSE
            } DEBUG_ELSE
        } DEBUG_ELSE
    } DEBUG_ELSE
    return false;
}

#pragma mark - kdebug_signpost

#define kBDJTPageInKDebugTag 6873

static void _bdjt_markAppLaunchStart(void) {
    if (@available(iOS 10.0, *)) {
        kdebug_signpost_start(kBDJTPageInKDebugTag, 0, 0, 0, 3);
    }
}

static void _bdjt_markAppLaunchFinish(void) {
    if (@available(iOS 10.0, *)) {
        kdebug_signpost_end(kBDJTPageInKDebugTag, 0, 0, 0, 3);
    }
}

#pragma mark - UIViewController

@interface UIViewController (BDJTPageInPreloader)

@end

@implementation UIViewController (BDJTPageInPreloader)

- (void)bdjt_viewDidAppear:(BOOL)animated {
    [self bdjt_viewDidAppear:animated];
    // Finish PageIn Collection
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _bdjt_markAppLaunchFinish();
    });
}

@end

static void _bdjt_registerViewDidAppearCallback(void) {
    _bdjt_swizzle_instance_method([UIViewController class], @selector(viewDidAppear:), @selector(bdjt_viewDidAppear:));
}

#define BDJTPreloadDirectoryName @"Jato"
#define BDJTPreloadConfigFileName @"jato_preload_config.json"

#define BDJTPreloadOptionsKey @"options"

#pragma mark - GCD Queues

static dispatch_queue_t _bdjt_preloadQueue(void) {
    static dispatch_queue_t preloadQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        preloadQueue = dispatch_queue_create("jato_preload_queue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0));
    });
    return preloadQueue;
}

#pragma mark - Prelaod Config

static NSString *_bdjt_root_directory(void) { /** ~/Library/Jato */
    return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:BDJTPreloadDirectoryName];
}

static NSString *_bdjt_config_file(void) { /** ~/Library/Jato/jato_preload_config.json */
    return [_bdjt_root_directory() stringByAppendingPathComponent:BDJTPreloadConfigFileName];
}

static NSString *_bdjt_preload_file;                /** Preload Config */
static BDJTPreloadOptions _bdjt_preload_options;    /** Preload Config */

BOOL _bdjt_isPreloadEnable(void) {
    static BOOL _bdjt_isEnabled = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *preloadConfigStr = [NSString stringWithContentsOfFile:_bdjt_config_file() encoding:NSUTF8StringEncoding error:nil];
        NSDictionary *preloadConfig = [preloadConfigStr btd_jsonDictionary];
        _bdjt_preload_options = [preloadConfig btd_unsignedIntegerValueForKey:BDJTPreloadOptionsKey];
        _bdjt_isEnabled = preloadConfig.count > 0;
    });
    return _bdjt_isEnabled;
}

static BOOL _bdjt_setPreloadConfig(BDJTPreloadOptions preloadOptions) {
    NSString *configFile = _bdjt_config_file();
    NSString *rootDirectory = _bdjt_root_directory();
    BOOL isDirectory = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:rootDirectory isDirectory:&isDirectory];
    if (isExists && !isDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:rootDirectory error:nil];
    }
    if (!isExists || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:rootDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSDictionary *config = @{BDJTPreloadOptionsKey : @(preloadOptions)};
    NSString *configStr = [config btd_jsonStringEncoded];
    return [configStr writeToFile:configFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

static BOOL _bdjt_removePreloadConfig(void) {
    return [[NSFileManager defaultManager] removeItemAtPath:_bdjt_config_file() error:nil];
}

#pragma mark - MachO

static uint64_t _bdjt_firstLoadCommand(const struct mach_header *header) {
    if (NULL == header) {
        return 0;
    }
    switch(header->magic) {
        case MH_MAGIC:
        case MH_CIGAM:
            return (uint64_t)(header + 1);
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            return (uint64_t)(((struct mach_header_64*)header) + 1);
        default:
            return 0;
    }
}

static uint64_t _bdjt_getSegmentAddress(const struct mach_header *header, intptr_t slide, const char *segmentName, uint64_t *outSize) {
    uint64_t cmdPtr = _bdjt_firstLoadCommand(header);
    if (cmdPtr == 0) {
        return 0;
    }
    for (uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++) {
        const struct load_command *loadCmd = (struct load_command *)cmdPtr;
        if (loadCmd->cmd == LC_SEGMENT) {
            const struct segment_command *segCmd = (struct segment_command *)cmdPtr;
            if (strcmp(segCmd->segname, segmentName) == 0) {
                if (outSize) {
                    *outSize = segCmd->vmsize;
                }
                return segCmd->vmaddr + slide;
            }
        } else if (loadCmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *segCmd = (struct segment_command_64 *)cmdPtr;
            if (strcmp(segCmd->segname, segmentName) == 0) {
                if (outSize) {
                    *outSize = segCmd->vmsize;
                }
                return segCmd->vmaddr + slide;
            }
        }
        cmdPtr += loadCmd->cmdsize;
    }
    return 0;
}

const uint8_t *_bdjt_uuidBytes(const struct mach_header *header) {
    uintptr_t cmdPtr = _bdjt_firstLoadCommand(header);
    if (cmdPtr == 0) {
        return NULL;
    }
    for (uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++) {
        const struct load_command *loadCmd = (struct load_command *)cmdPtr;
        if (loadCmd->cmd == LC_UUID) {
            struct uuid_command *uuidCmd = (struct uuid_command *)cmdPtr;
            return uuidCmd->uuid;
        }
        cmdPtr += loadCmd->cmdsize;
    }
    return NULL;
}

static NSString *_bdjt_uuidBytesToString(const uint8_t *uuidBytes) {
    return [[[NSUUID alloc] initWithUUIDBytes:uuidBytes] UUIDString];
}

NSString *_bdjt_imageUUID(const struct mach_header *header) {
    const uint8_t *uuidBytes = _bdjt_uuidBytes(header);
    if (uuidBytes) {
        return _bdjt_uuidBytesToString(uuidBytes);
    }
    return nil;
}

#pragma mark - Preload Contents

static NSDictionary<NSString *, NSArray<NSString *> *> *_bdjt_pageInDictionary() {
    static NSDictionary<NSString *, NSArray<NSString *> *> *_bdjt_preloadAddressDict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *addressFileContents = [NSString stringWithContentsOfFile:_bdjt_preload_file encoding:NSUTF8StringEncoding error:nil];
        _bdjt_preloadAddressDict = [addressFileContents btd_jsonDictionary];
    });
    return _bdjt_preloadAddressDict;
}

static NSDictionary<NSString *, NSArray<NSString *> *> *_bdjt_pageInAddressDict(NSString *imageName) {
    if (imageName.length == 0) {
        return nil;
    }
    NSDictionary *imageInfo = [_bdjt_pageInDictionary() btd_dictionaryValueForKey:imageName];
    return [imageInfo btd_dictionaryValueForKey:@(vm_kernel_page_size).stringValue];
}

NSString *_bdjt_pageInImageUUID(NSString *imageName) {
    if (imageName.length == 0) {
        return nil;
    }
    NSDictionary *imageInfo = [_bdjt_pageInDictionary() btd_dictionaryValueForKey:imageName];
    return [imageInfo btd_stringValueForKey:@"uuid"];
}

#pragma mark - Preload

static atomic_bool _bdjt_preloadAvailable = false;

static void _bdjt_preloadPages(const struct mach_header *header, intptr_t slide, NSString *imageName) {
    if (imageName.length == 0) {
        return;
    }
    static unsigned long long bdjt_flag; // Address累加，防止编译器优化
    dispatch_async(_bdjt_preloadQueue(), ^{
        BOOL shouldReverse = _bdjt_preload_options & BDJTPreloadReverse;
        NSString *preloadUUID = _bdjt_pageInImageUUID(imageName);
        NSString *imageUUID = _bdjt_imageUUID(header);
        if ([preloadUUID isEqualToString:imageUUID] == NO) {
            _bdjt_preloadAvailable = false;
            return;
        }
        NSDictionary<NSString *, NSArray<NSString *> *> *addressDict = _bdjt_pageInAddressDict(imageName);
        [addressDict enumerateKeysAndObjectsUsingBlock:^(NSString *segmentName, NSArray<NSString *> *addressArray, BOOL *stop) {
            if ([addressArray isKindOfClass:[NSArray class]]) {
                uint64_t segmentVmSize = 0;
                uint64_t segmentAddress = _bdjt_getSegmentAddress(header, slide, segmentName.UTF8String, &segmentVmSize);
                if (segmentAddress) {
                    NSUInteger addressCount = addressArray.count;
                    void (^preloadBlock)(NSUInteger) = ^(NSUInteger index){
                        NSString *offsetStr = [addressArray btd_objectAtIndex:shouldReverse ? addressCount - index - 1 : index];
                        if ([offsetStr isKindOfClass:[NSString class]] || [offsetStr isKindOfClass:[NSNumber class]]) {
                            uint64_t offsetValue = offsetStr.longLongValue;
                            if (offsetValue < segmentVmSize) {
                                uint64_t addr = segmentAddress + offsetValue;
                                uint64_t obj = *(uint64_t *)addr;
                                bdjt_flag += obj;
                            }
                        }
                    };
                    if (_bdjt_preload_options & BDJTPreloadConcurrent) {
                        dispatch_apply(addressCount, DISPATCH_APPLY_AUTO, ^(size_t iteration) {
                            preloadBlock(iteration);
                        });
                    } else {
                        for (NSUInteger iteration = 0; iteration < addressCount; iteration++) {
                            preloadBlock(iteration);
                        }
                    }
                }
            }
            else {
                *stop = YES;
                _bdjt_preloadAvailable = false;
            }
        }];
    });
}

static atomic_bool _bdjt_preloadFinish;
static NSArray<NSString *> *_bdjt_preloadImages;

static void _bdjt_addImageCallback(const struct mach_header *header, intptr_t slide) {
    if (_bdjt_preloadFinish) {
        return;
    }
    Dl_info info;
    if (dladdr(header, &info) == 0) {
        return;
    }
    if (NULL == info.dli_fname) {
        return;
    }
    NSString *executablePath = [NSString stringWithCString:info.dli_fname encoding:NSUTF8StringEncoding];
    NSString *imageName = executablePath.lastPathComponent;
    if ([_bdjt_preloadImages containsObject:imageName]) {
        _bdjt_preloadPages(header, slide, imageName);
    }
}

#pragma mark - Collection

BOOL _bdjt_shouldStartCollect(void) {
    static BOOL _bdjt_shouldCollect = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *environment = [[NSProcessInfo processInfo] environment];
        id res = [environment objectForKey:@"BDJatoPageInCollection"];
        _bdjt_shouldCollect = res && [res boolValue];
    });
    return _bdjt_shouldCollect;
}

#pragma mark - Interface

BOOL bdjt_isPreloadEnabled(void) {
    return _bdjt_isPreloadEnable() && _bdjt_preloadAvailable;
}

BOOL bdjt_isCollectingData(void) {
    return _bdjt_shouldStartCollect();
}

BDJTPreloadOptions bdjt_getPreloadOptions(void) {
    return _bdjt_preload_options;
}

void bdjt_startPreloadIfEnabled(NSString *pageInFilePath) {
    dispatch_async(_bdjt_preloadQueue(), ^{
        if (_bdjt_shouldStartCollect()) {
            _bdjt_markAppLaunchStart();
            _bdjt_registerViewDidAppearCallback();
        } else {
            if (_bdjt_isPreloadEnable()) {
                _bdjt_removePreloadConfig();
                if (pageInFilePath.length && [[NSFileManager defaultManager] fileExistsAtPath:pageInFilePath]) {
                    _bdjt_preloadAvailable = true;
                    _bdjt_preload_file = [pageInFilePath copy];
                    _bdjt_preloadImages = [_bdjt_pageInDictionary() allKeys];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), _bdjt_preloadQueue(), ^{
                        _bdjt_preloadFinish = true;
                    });
                    _dyld_register_func_for_add_image(_bdjt_addImageCallback);
                }
            }
        }
    });
}

void bdjt_setupPreloadForNextLaunch(BDJTPreloadOptions preloadOptions) {
    dispatch_async(_bdjt_preloadQueue(), ^{
        _bdjt_setPreloadConfig(preloadOptions);
    });
}

void bdjt_disablePreloadForNextLaunch(void) {
    dispatch_async(_bdjt_preloadQueue(), ^{
        _bdjt_removePreloadConfig();
    });
}
