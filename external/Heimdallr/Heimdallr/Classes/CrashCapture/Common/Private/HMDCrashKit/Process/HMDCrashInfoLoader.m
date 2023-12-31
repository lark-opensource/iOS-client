//
//  HMDCrashInfoLoader.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#include <sys/stat.h>
#include <mach/vm_statistics.h>
#include "HMDMacro.h"
#include "HMDCrashDynamicSavedFiles.h"
#import "HMDCrashInfoLoader.h"
#import "NSString+HMDJSON.h"
#import "NSString+HMDCrash.h"
#import "HMDInvalidThreadsJSONParser.h"
#import "NSString+HMDSafe.h"
#import "HMDCrashRegisterAnalysis.h"
#import "HMDCrashStackAnalysis.h"
#import "HMDCrashVMRegion.h"

#pragma mark - class extension (objc_direct)
/// @code
/// 我们这里只是声明以下方法会参加 objc_direct 直接调用
/// 它的作用是不再走 objc_msgSend 消息转发，而是直接 IMP 调用的形式
/// 参考文档: https://reviews.llvm.org/D69991

CLANG_ATTR_OBJC_DIRECT_MEMBERS
@interface HMDCrashInfoLoader ()

+ (void)parseBinaryImageFiles:(HMDCrashInfo *)info inputDir:(NSString *)inputDir;

+ (void)parseMetaFile:(HMDCrashInfo *)info inputDir:(NSString *)inputDir;

+ (void)parseExceptionFile:(HMDCrashInfo *)info inputDir:(NSString *)inputDir;

+ (NSArray<NSString *> * _Nullable)tryRecoverExceptionFile:(NSString * _Nonnull)filePath;

+ (NSDictionary * _Nullable)tryRecoverThreads:(NSString * _Nonnull)corruptedString
                                         info:(HMDCrashInfo *)info;

+ (void)appendImageToStackRecord:(HMDCrashInfo *)info;

+ (void)parseDynamicFile:(HMDCrashInfo *)info inputDir:(NSString *)inputDir;

+ (NSDictionary * _Nullable)readDynamicInfoFromDictionary:(NSDictionary * _Nonnull)dynamicDictionary;

+ (void)copySaveFiles:(NSArray<id> *)saveFilesArray inputDir:(NSString *)inputDir;

+ (void)parseVMMapFile:(HMDCrashInfo *)info inputDir:(NSString *)inputDir;

+ (void)updateVMMap:(NSArray<HMDCrashVMRegion *> *)regions
             images:(NSArray<HMDCrashBinaryImage *> *)images;

+ (void)parseMemoryFile:(HMDCrashInfo *)info inputDir:(NSString *)inputDir;

+ (void)updateAddressAnalysis:(HMDCrashAddressAnalysis *)analysis
                         info:(HMDCrashInfo *)info;

+ (void)parseSDKLog:(HMDCrashInfo *)info inputDir:(NSString *)inputDir;

+ (NSString * _Nullable)loadFileContent:(NSString *)path
                                   info:(HMDCrashInfo *)info;

@end

@implementation HMDCrashInfoLoader

#pragma mark - Implementation

+ (HMDCrashInfo *)loadCrashInfo:(NSString *)inputDir {
    HMDCrashInfo *info = [[HMDCrashInfo alloc] init];
    
    [info info:@"start process crashlog"];
    
    /// @code Binary Image 文件由三部分组成
    /// image.main 存储由 _dyld_add_image_callback 在子线程异步产生的 image 信息
    /// image.loadCommand 存储在 dyld loadCommand 内部存储的 image 信息
    /// image.realTime 是在崩溃发生时刻，如果 image.main 的存储尚未完成时刻，主动存储的 image 信息
    [self parseBinaryImageFiles:info inputDir:inputDir];

    /// @code meta 文件
    /// 存储在生命周期中，不会发生改变的数据
    [self parseMetaFile:info inputDir:inputDir];
    
    /// @code exception 文件
    /// 存储调用栈信息，以及 processInfo 这类和崩溃报告强相关的信息
    [self parseExceptionFile:info inputDir:inputDir];
    
    /// @code appendRecord
    /// 利用 exception 文件和 binaryImage 文件，给调用栈信息匹配对应的镜像
    [self appendImageToStackRecord:info];
    
    /// @code dynamic 文件
    /// 任何运行时动态的信息都应该存储在 dynamic 文件中
    /// 除非改文件实在比较大，导致需要单独开个文件进行存储，例如以下文件
    [self parseDynamicFile:info inputDir:inputDir];
    
    /// @code vmmap 文件
    /// 存储在崩溃捕获过程中，抓取到的 virtual memory region 信息
    [self parseVMMapFile:info inputDir:inputDir];
    
    /// @code memory 文件
    /// 存储在崩溃捕获过程中，抓取到的栈内存信息，包括各寄存器的地址反解析
    [self parseMemoryFile:info inputDir:inputDir];
    
    /// @code sdk_info 文件
    /// 存储在崩溃捕获过程中，产生的日志信息
    [self parseSDKLog:info inputDir:inputDir];
    
    return info;
}

#pragma mark parseBinaryImageFiles

+ (void)parseBinaryImageFiles:(HMDCrashInfo *)info inputDir:(NSString *)inputDir {
    info.imageLoader = [[HMDImageOpaqueLoader alloc] initWithDirectory:inputDir];
}

#pragma mark parseMetaFile

+ (void)parseMetaFile:(HMDCrashInfo *)info inputDir:(NSString *)inputDir {

    NSString *fileName = @"meta";
    
    [info info:@"start process %@",fileName];
    
    NSString *path = [inputDir stringByAppendingPathComponent:fileName];
    
    NSString *content = [self loadFileContent:path info:info];
    
    NSDictionary *dict = [content hmd_jsonDict];
    
    if (dict.count == 0) {
        [info error:@"meta content:\n%@", content];
        return;
    }
    
    HMDCrashMetaData *meta = [HMDCrashMetaData objectWithDictionary:dict];
    info.meta = meta;
}

#pragma mark parseExceptionFile

+ (void)parseExceptionFile:(HMDCrashInfo *)info inputDir:(NSString *)inputDir {
    NSError *error = nil;

    NSString *fileName = @"exception";
    
    [info info:@"start process %@",fileName];
    
    NSString *exceptionFilePath = [inputDir stringByAppendingPathComponent:fileName];
    
    BOOL needUploadCorruptedExceptionFile = NO;
    
    NSString *content = [self loadFileContent:exceptionFilePath info:info];
    
    NSArray<NSString *> * _Nullable strings;
    
    if(content == nil) {
        strings = [self tryRecoverExceptionFile:exceptionFilePath];
    } else {
        strings = [content componentsSeparatedByString:@"\n"];
    }
    
    if(strings.count == 0) needUploadCorruptedExceptionFile = YES;
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:exceptionFilePath error:&error];
    info.exceptionFileModificationDate = [attributes objectForKey:NSFileModificationDate];
    
    for(NSString *eachLineString in strings) {
        NSDictionary * _Nullable dictionary = [eachLineString hmd_jsonDict];
        
        if(dictionary == nil) {
            dictionary = [self tryRecoverThreads:eachLineString info:info];
        }
        
        if(dictionary == nil) continue;
        
        NSDictionary *exceptionDictionary = nil;
        if((exceptionDictionary = [dictionary hmd_dictForKey:@"exception"]) != nil) {
            info.headerInfo = [HMDCrashHeaderInfo objectWithDictionary:exceptionDictionary];
            continue;
        }
        
        NSArray *threadsArray = nil;
        if((threadsArray = [dictionary hmd_arrayForKey:@"threads"]) != nil) {
            info.threads = [HMDCrashThreadInfo objectsWithDicts:threadsArray];
            continue;
        }
        
        NSDictionary *asyncStackDictionary;
        if((asyncStackDictionary = [dictionary hmd_dictForKey:@"stack_record"]) != nil) {
            info.stackRecord = [HMDCrashThreadInfo objectWithDictionary:asyncStackDictionary];
            info.stackRecord.threadName = [asyncStackDictionary hmd_stringForKey:@"thread_name"];
            continue;
        }
        
        
        NSDictionary *runtimeInfoDictionary;
        if((runtimeInfoDictionary = [dictionary hmd_dictForKey:@"runtime_info"]) != nil) {
            info.runtimeInfo = [HMDCrashRuntimeInfo objectWithDictionary:runtimeInfoDictionary];
            continue;
        }
        
        NSArray *dispatchNameArray = nil;
        if((dispatchNameArray = [dictionary hmd_arrayForKey:@"dispatch_name"]) != nil) {
            info.queueNames = dispatchNameArray;
            continue;
        }
        
        NSArray *pthreadNameArray = nil;
        if((pthreadNameArray = [dictionary hmd_arrayForKey:@"pthread_name"]) != nil) {
            info.threadNames = pthreadNameArray;
            continue;
        }
        
        NSDictionary *processDictionary = nil;
        if((processDictionary = [dictionary hmd_dictForKey:@"process_stats"]) != nil) {
            info.processState = [HMDCrashProcessState objectWithDictionary:processDictionary];
            continue;
        }
        
        NSDictionary *storageDictionary = nil;
        if((storageDictionary = [dictionary hmd_dictForKey:@"storage"]) != nil) {
            info.storage = [HMDCrashStorage objectWithDictionary:storageDictionary];
            continue;
        }
        
        
        NSArray *registerAnalysisArray = nil;
        if((registerAnalysisArray = [dictionary hmd_arrayForKey:@"register_analyze"]) != nil) {
            info.registerAnalysis = [HMDCrashRegisterAnalysis objectsWithDicts:registerAnalysisArray];
            continue;
        }
        
        NSArray *stackAnalysisArray = nil;
        if((stackAnalysisArray = [dictionary hmd_arrayForKey:@"stack_analyze"]) != nil) {
            info.stackAnalysis = [HMDCrashStackAnalysis objectsWithDicts:stackAnalysisArray];
            continue;
        }
        
        
        {   // Forward compact
            // Delete when not needed
            // Date: 2023-02-22
            
            NSDictionary *dynamicDictionary = nil;
            if((dynamicDictionary = [dictionary hmd_dictForKey:@"dynamic"]) != nil) {
                info.dynamicInfo = [self readDynamicInfoFromDictionary:dynamicDictionary];
                continue;
            }
            
            NSDictionary *extraDynamicDictionary = nil;
            if((extraDynamicDictionary = [dictionary hmd_dictForKey:@"extra_dynamic"]) != nil) {
                info.extraDynamicInfo = [self readDynamicInfoFromDictionary:extraDynamicDictionary];
                continue;
            }
        }
    }
    
    if (info.headerInfo == nil) {
        [info error:@"header info missing"];
        needUploadCorruptedExceptionFile = NO;
    }
    if (info.threads.count == 0) {
        [info error:@"threads info missing"];
        needUploadCorruptedExceptionFile = NO;
    }
    if (info.queueNames == nil) {
        [info error:@"queue name info missing"];
        needUploadCorruptedExceptionFile = NO;
    }
    if (info.threadNames == nil) {
        [info error:@"thread name info missing"];
        needUploadCorruptedExceptionFile = NO;
    }
    if (info.processState == nil) {
        [info error:@"process stat info missing"];
        needUploadCorruptedExceptionFile = NO;
    }
    if (info.storage == nil) {
        [info error:@"storage info missing"];
        needUploadCorruptedExceptionFile = NO;
    }
    
    if(!needUploadCorruptedExceptionFile) return;
    
    info.isCorrupted = YES;
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:exceptionFilePath]) return;
    
    NSString *extendDir = [inputDir stringByAppendingPathComponent:@"Extend"];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:extendDir]) return;
    
    [[NSFileManager defaultManager] moveItemAtPath:exceptionFilePath
                                            toPath:[extendDir stringByAppendingPathComponent:fileName]
                                             error:nil];
}

#define MAX_RECOVER_EXCEPTION_FILE_SIZE (1024 * 1024)   // 1MB

+ (NSArray<NSString *> * _Nullable)tryRecoverExceptionFile:(NSString * _Nonnull)filePath {
    
    NSMutableArray<NSString *> *result = nil;
    
    NSString *standardPath = [filePath stringByStandardizingPath];
    const char *rawFilePath = standardPath.UTF8String;
    
    int fileDescriptor = open(rawFilePath, O_RDONLY | O_NOFOLLOW);
    
    if(fileDescriptor < 0) return nil;
    
    struct stat fileStatus;
    if(fstat(fileDescriptor, &fileStatus) != 0)
        goto clean_FD;
    
    off_t fileSize = fileStatus.st_size;
    
    if(fileSize == 0 || fileSize > MAX_RECOVER_EXCEPTION_FILE_SIZE)
        goto clean_FD;
    
    char * _Nullable tempStorage = malloc(fileStatus.st_size);
    
    if(tempStorage == nil)
        goto clean_FD;
    
    ssize_t readAmount = read(fileDescriptor, tempStorage, fileStatus.st_size);
    
    if(readAmount <= 0 || readAmount > fileSize)
        goto clean_storage_FD;
    
    result = NSMutableArray.array;
    
    ssize_t lineBeginIndex = 0;
    
    for(ssize_t index = 0; index < readAmount; index++) {
        
        // reach the end of file
        if(tempStorage[index] == '\0') break;
        
        // not meeting any file break
        if(tempStorage[index] != '\n') continue;
        
        // no line exist
        if(lineBeginIndex == index) break;
        
        // mark end of string
        tempStorage[index] = '\0';
        
        NSString * _Nullable lineString = nil;
        
        lineString = [NSString stringWithCString:tempStorage + lineBeginIndex
                                        encoding:NSUTF8StringEncoding];
        
        if(lineString != nil) {
            [result addObject:lineString];
        }
        
        lineBeginIndex = index + 1;
    }
    
clean_storage_FD:
    free(tempStorage);
clean_FD:
    close(fileDescriptor);
    
    return result;
}

+ (NSDictionary * _Nullable)tryRecoverThreads:(NSString * _Nonnull)corruptedString
                                         info:(HMDCrashInfo *)info {
    
    // threads means stack info, try recover as much as possible
    NSString *topTenSubstring = [corruptedString hmd_substringToIndex:10];
    if(![topTenSubstring containsString:@"threads"]) return nil;
    
    info.isInvalid = YES;
    
    HMDInvalidThreadsJSONParser *invalidJSONParser = [[HMDInvalidThreadsJSONParser alloc] init];
    return [invalidJSONParser parseInvalidThreadsJSONWithString:corruptedString];
}

#pragma mark appendImageToStackRecord

+ (void)appendImageToStackRecord:(HMDCrashInfo *)info {
    [info.stackRecord generateFrames:info.imageLoader];
    
    [info.threads enumerateObjectsUsingBlock:^(HMDCrashThreadInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj generateFrames:info.imageLoader];
        obj.queueName = [info.queueNames hmd_objectAtIndex:idx class:NSString.class];
        obj.pthreadName = [info.threadNames hmd_objectAtIndex:idx class:NSString.class];
    }];
    
    info.currentlyUsedImages = info.imageLoader.currentlyUsedImages;
}

#pragma mark parseDynamicFile

+ (void)parseDynamicFile:(HMDCrashInfo *)info inputDir:(NSString *)inputDir {
    
    NSString *fileName = @"dynamic";
    
    [info info:@"start process %@",fileName];
    
    NSString *path = [inputDir stringByAppendingPathComponent:fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return;
    }
    
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    if (content.length == 0 || error != nil) return;
    
    NSArray<NSString *> * strings = [content componentsSeparatedByString:@"\n"];
    
    for(NSString *eachLineString in strings) {
        NSDictionary * _Nullable dictionary = [eachLineString hmd_jsonDict];
        
        if(dictionary == nil) continue;
        
        NSDictionary *dynamicDictionary = nil;
        if((dynamicDictionary = [dictionary hmd_dictForKey:@"dynamic"]) != nil) {
            info.dynamicInfo = [self readDynamicInfoFromDictionary:dynamicDictionary];
            continue;
        }
        
        NSDictionary *extraDynamicDictionary = nil;
        if((extraDynamicDictionary = [dictionary hmd_dictForKey:@"extra_dynamic"]) != nil) {
            info.extraDynamicInfo = [self readDynamicInfoFromDictionary:extraDynamicDictionary];
            continue;
        }
        
        NSArray *vids = nil;
        if ((vids = [dictionary hmd_arrayForKey:@"vids"]) != nil) {
            info.vids = vids;
        }
        
        NSArray<id> *saveFilesArray = nil;
        if((saveFilesArray = [dictionary hmd_arrayForKey:@"save_files"]) != nil) {
            [self copySaveFiles:saveFilesArray inputDir:inputDir];
        }
        
        NSString *gameScriptStack = nil;
        if((gameScriptStack = [dictionary hmd_stringForKey:@"game_script_stack"]) != nil) {
            NSString *decodeString = [gameScriptStack hmdcrash_stringWithHex];
            if(decodeString != nil) info.gameScriptStack = decodeString;
        }
    }
}

+ (NSDictionary * _Nullable)readDynamicInfoFromDictionary:(NSDictionary * _Nonnull)dynamicDictionary {
    
    NSMutableDictionary *resultDictionary = NSMutableDictionary.dictionary;
    
    [dynamicDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSString *  _Nonnull value, BOOL * _Nonnull stop) {
        
        if(![key isKindOfClass:NSString.class]) return;
        if(![value isKindOfClass:NSString.class]) return;

        NSString *decodeValue = [value hmdcrash_stringWithHex];
        if(decodeValue == nil) return;
        
        [resultDictionary hmd_setObject:decodeValue forKey:key];
    }];
    
    return resultDictionary;
}

+ (void)copySaveFiles:(NSArray<id> *)saveFilesArray inputDir:(NSString *)inputDir {
    NSString *homePath = NSHomeDirectory();
    NSFileManager *manager = [NSFileManager defaultManager];
    
    uint64_t total_size_limit = 0;
    
    for(id maybeString in saveFilesArray) {
        if(![maybeString isKindOfClass:NSString.class]) continue;
        
        NSString *absolutePath = [homePath stringByAppendingPathComponent:maybeString];
        const char *absoluteRawPath = absolutePath.UTF8String;
        if(absoluteRawPath == NULL) continue;
        
        struct stat file_status;
        
        if(lstat(absoluteRawPath, &file_status) != 0) continue;
        if((file_status.st_mode & S_IFMT) != S_IFREG) continue;
        
        uint64_t file_size = file_status.st_size;
        if(file_size > HMD_CRASH_DYNAMIC_SAVED_FILE_MAX_SIZE)
            break;
        
        total_size_limit += file_size;
        if(total_size_limit > HMD_CRASH_DYNAMIC_SAVED_FILES_TOTAL_SIZE_LIMIT)
            break;
        
        
        
        NSString *extendDir = [inputDir stringByAppendingPathComponent:@"Extend"];
        
        BOOL isDirectory = NO;
        if(![manager fileExistsAtPath:extendDir isDirectory:&isDirectory]) break;
        if(!isDirectory) break;
        
        NSString *fileName = absolutePath.lastPathComponent;
        NSString *moveToPath = [extendDir stringByAppendingPathComponent:fileName];

        [manager moveItemAtPath:absolutePath
                         toPath:moveToPath
                          error:nil];
        
        DEBUG_LOG("successfully move dynamic file from %s to %s",
                  absoluteRawPath, moveToPath.UTF8String);
    }
}

#pragma mark parseVMMapFile

+ (void)parseVMMapFile:(HMDCrashInfo *)info inputDir:(NSString *)inputDir {
    NSError *error = nil;

    NSString *fileName = @"vmmap";
    
    [info info:@"start process %@",fileName];
    
    NSString *path = [inputDir stringByAppendingPathComponent:fileName];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) return;
    
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (content.length == 0 || error) return;
    
    NSArray * regionStrs = [content componentsSeparatedByString:@"\n"];
    NSMutableArray *regions = [NSMutableArray array];
    [regionStrs enumerateObjectsUsingBlock:^(NSString*  _Nonnull str, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            if (str.length > 0) {
                NSDictionary *dict = [str hmd_jsonDict];
                if (dict.count) {
                    HMDCrashVMRegion *region = [HMDCrashVMRegion objectWithDictionary:dict];
                    [regions hmd_addObject:region];
                }
            }
        }
    }];
    
    /*
    {
        NSMutableArray *desc = [NSMutableArray array];
        [regions enumerateObjectsUsingBlock:^(HMDCrashVMRegion * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *str = [NSString stringWithFormat:@"%018lx - %018lx %@ %@",obj.base,obj.base+obj.size,obj.userTagString?:@"",obj.file.lastPathComponent?:@""];
            [desc addObject:str];
        }];
        NSString *str = [desc componentsJoinedByString:@"\n"];
        [str writeToFile:[basePath stringByAppendingPathComponent:@"vmmap_string"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
    {
        NSArray *images = [info.images sortedArrayUsingComparator:^NSComparisonResult(HMDCrashBinaryImage * _Nonnull obj1, HMDCrashBinaryImage *  _Nonnull obj2) {
            if (obj1.base > obj2.base) {
                return NSOrderedDescending;
            } else if (obj1.base == obj2.base) {
                return NSOrderedSame;
            } else {
                return NSOrderedAscending;
            }
        }];
        NSMutableArray *desc = [NSMutableArray array];
        [images enumerateObjectsUsingBlock:^(HMDCrashBinaryImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
            [image.segments enumerateObjectsUsingBlock:^(HMDCrashSegment * _Nonnull segment, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *str = [NSString stringWithFormat:@"%018llx - %018llx %@.%@",segment.base,segment.base+segment.size,image.path.lastPathComponent,segment.segmentName];
                [desc addObject:str];
            }];
        }];
        NSString *str = [desc componentsJoinedByString:@"\n"];
        [str writeToFile:[basePath stringByAppendingPathComponent:@"image_string"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
     */
    
    [self updateVMMap:regions images:info.currentlyUsedImages];
    
    info.regions = regions;
    
    [info info:@"vmregion count = %lu", regions.count];
}

+ (void)updateVMMap:(NSArray<HMDCrashVMRegion *> *)regions images:(NSArray<HMDCrashBinaryImage *> *)images {
    [regions enumerateObjectsUsingBlock:^(HMDCrashVMRegion * _Nonnull region, NSUInteger idx, BOOL * _Nonnull s1) {
        vm_address_t regionStart = region.base;
        if (region.user_tag == 0) {
            [images enumerateObjectsUsingBlock:^(HMDCrashBinaryImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull s2) {
                [image.segments enumerateObjectsUsingBlock:^(HMDCrashSegment * _Nonnull segment, NSUInteger idx, BOOL * _Nonnull s3) {
                    vm_address_t segmentStart = segment.base;
                    vm_address_t segmentEnd = segment.base + segment.size;
                    if ((regionStart >= segmentStart && regionStart < segmentEnd)) {
                        region.segment = segment;
                        *s3 = YES;
                    }
                }];
                if (region.segment) {
                    region.image = image;
                    *s2 = YES;
                }
            }];
        }
    }];
}

#pragma mark parseMemoryFile

+ (void)parseMemoryFile:(HMDCrashInfo *)info inputDir:(NSString *)inputDir {
    NSError *error = nil;

    NSString *fileName = @"memory";
    
    [info info:@"start process %@",fileName];
    
    NSString *path = [inputDir stringByAppendingPathComponent:fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return;
    }
    
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    if (content.length == 0 || error) {
        return;
    }
    
    NSArray * strs = [content componentsSeparatedByString:@"\n"];
    NSMutableArray *registers = [NSMutableArray array];
    NSMutableArray *addresses = [NSMutableArray array];
    [strs enumerateObjectsUsingBlock:^(NSString*  _Nonnull str, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            if (str.length > 0) {
                NSDictionary *dict = [str hmd_jsonDict];
                if (dict.count) {
                    if ([dict hmd_hasKey:@"name"]) {
                        HMDCrashRegisterAnalysis *obj = [HMDCrashRegisterAnalysis objectWithDictionary:dict];
                        [self updateAddressAnalysis:obj info:info];
                        [registers hmd_addObject:obj];
                    } else if ([dict hmd_hasKey:@"address"]) {
                        HMDCrashStackAnalysis *obj = [HMDCrashStackAnalysis objectWithDictionary:dict];
                        [self updateAddressAnalysis:obj info:info];
                        [addresses hmd_addObject:obj];
                    }
                }
            }
        }
    }];
            
    info.registerAnalysis = registers;
    info.stackAnalysis = addresses;
    
    [info info:@"register count = %lu address count = %lu",registers.count,addresses.count];
}

+ (void)updateAddressAnalysis:(HMDCrashAddressAnalysis *)analysis
                         info:(HMDCrashInfo *)info {
    uintptr_t value = analysis.value;
    [info.regions enumerateObjectsUsingBlock:^(HMDCrashVMRegion * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (value >= obj.base && value < (obj.base + obj.size)) {
            analysis.regionInfo = obj;
            *stop = YES;
        }
    }];
//    if (info.regions.count > 0 && !analysis.regionInfo) {
//        return; //no region info means invalid address
//    }
    if (analysis.regionInfo.user_tag == VM_MEMORY_STACK) {
        analysis.objectInfo = nil;
        analysis.stringInfo = nil;
        return;
    }
    [info.currentlyUsedImages enumerateObjectsUsingBlock:^(HMDCrashBinaryImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull s1) {
        [image.segments enumerateObjectsUsingBlock:^(HMDCrashSegment * _Nonnull segment, NSUInteger idx, BOOL * _Nonnull s2) {
            if (value >= segment.base && value < (segment.base + segment.size)) {
                [segment.sections enumerateObjectsUsingBlock:^(HMDCrashSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull s3) {
                    if (value >= section.base && value < (section.base + section.size)) {
                        analysis.section = section;
                        *s3 = YES;
                    }
                }];
                analysis.segment = segment;
                *s2 = YES;
            }
        }];
        if (analysis.segment) {
            analysis.image = image;
            *s1 = YES;
        }
    }];
}

#pragma mark parseSDKLog

+ (void)parseSDKLog:(HMDCrashInfo *)info inputDir:(NSString *)inputDir  {
    NSString *path = [inputDir stringByAppendingPathComponent:@"sdk_info"];
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    info.sdklog = content;
}

#pragma mark tool

+ (NSString * _Nullable)loadFileContent:(NSString *)path info:(HMDCrashInfo *)info {
    
    NSError *  _Nullable error = nil;
    NSString * _Nullable content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    if(content.length > 0) return content;
    
    info.fileIOError = YES;
    
    NSString *fileName = path.lastPathComponent;
    
    if(error != nil) [info error:@"%@ load error: %@", fileName, error.localizedDescription];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [info error:@"%@ file is missing", fileName];
        info.isCorrupted = YES;
        return nil;
    }
    
    error = nil;
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    
    if(error != nil) {
        [info error:@"%@ load error: %@", path.lastPathComponent, error.localizedDescription];
        return nil;
    }
    
    [info error:@"%@ file corrupted, file_size:%llu createDate:%@", fileName, attributes.fileSize, attributes.fileCreationDate];
    
    info.isCorrupted = YES;
    
    return nil;
}

@end
