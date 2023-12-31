//
//	HMDDiskSpaceDistribution.m
// 	Heimdallr
// 	
// 	Created by Hayden on 2020/6/3. 
//

#import "HMDDiskSpaceDistribution.h"
#import "Heimdallr+Private.h"
#import "HMDDiskUsage.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDALogProtocol.h"
#include "pthread_extended.h"
#import "NSArray+HMDSafe.h"
#import "HMDWeakProxy.h"
#import "HMDDynamicCall.h"
#include <sys/mount.h>
#import "HeimdallrUtilities.h"
#import "HMDServiceContext.h"
// PrivateServices
#import "HMDMonitorService.h"

@interface HMDDSDModuleInfo ()

@property (nonatomic, strong)HMDDSDEnumerateBlock block;
@property (nonatomic, assign)size_t needSize;
@property (nonatomic, assign)HMDDiskSpacePriority priority;
@property (nonatomic, assign)NSInteger callBackDirectlyCount;

@end

@implementation HMDDSDModuleInfo

@end

static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

@interface HMDDiskSpaceDistribution ()

@property (nonatomic, strong)dispatch_queue_t priorityQueue;
@property (nonatomic, strong)NSMutableDictionary<NSString *, id> *modules;
@property (nonatomic, copy)NSArray<Class> *moduleClass;
@property (nonatomic, strong)NSMutableArray<HMDDSDModuleInfo *> *callBacks;

@end

@implementation HMDDiskSpaceDistribution

+ (instancetype)sharedInstance {
    static HMDDiskSpaceDistribution *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[HMDDiskSpaceDistribution alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        _modules = [NSMutableDictionary dictionaryWithCapacity:4];
        _callBacks = [NSMutableArray array];
        _moduleClass = [self _moduleClassFromDefaultModuls];
        _priorityQueue = dispatch_queue_create("com.Heimdallr.DiskSpaceDistribution.serial", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (void)registerModule:(id<HMDInspectorDiskSpaceDistribution>)module {
    if (!module) return;
    if (!self.moduleClass.count) return;
    
    BOOL unknownModule = YES;
    
    pthread_mutex_lock(&mutex);
    for (Class cls in self.moduleClass) {
        if ([module isKindOfClass:cls]) {
            [self.modules hmd_setSafeObject:[HMDWeakProxy proxyWithTarget:module] forKey:NSStringFromClass(cls)];
            unknownModule = NO;
        }
    }
    pthread_mutex_unlock(&mutex);
    
    if (unknownModule) {
        NSAssert(NO, @"[HMDDiskSpaceDistribution] register unknown module : %@, please check and update map table in [removableFileModules]", NSStringFromClass(module.class));
        HMDALOG_PROTOCOL_FATAL(@"[HMDDiskSpaceDistribution] register unknown module : %@, please check and update map table in [removableFileModuls]", NSStringFromClass(module.class));
    }
}

- (void)getMoreDiskSpaceWithSize:(size_t)size priority:(HMDDiskSpacePriority)priority usingBlock:(HMDDSDEnumerateBlock)block {
    if (!block) return;
    
    // Save call back in priority queue
    pthread_mutex_lock(&mutex);
    HMDDSDModuleInfo *moduleInfo = [HMDDSDModuleInfo new];
    moduleInfo.needSize = size;
    moduleInfo.block = block;
    moduleInfo.priority = priority;
    [self _addCallBack2PriorityQueue:moduleInfo];
    pthread_mutex_unlock(&mutex);
    
    NSDictionary *startCategory = @{@"size":@(size), @"priority":@(priority)};
    HMDALOG_PROTOCOL_INFO(@"[HMDDiskSpaceDistribution] free start : %@", startCategory);
    
    dispatch_async(self.priorityQueue, ^{
        BOOL stop = NO;
        // Traverse the modules to remove file
        for (int i = 0; i < self.moduleClass.count; i++) {
            Class acls = [self.moduleClass hmd_objectAtIndex:i];
            BOOL moduleRegistered = NO;
            NSString *key = NSStringFromClass(acls);
            
            // Obtain instance of module
            pthread_mutex_lock(&mutex);
            HMDWeakProxy *module = [self.modules hmd_objectForKey:key class:acls];
            if (module && module.target) moduleRegistered = YES;
            pthread_mutex_unlock(&mutex);
            
            // Traverse the removable files to free from the class or instance of module
            NSMutableArray<NSDictionary *> *files = [self _removableFilesFromModule:acls];
            while (files.count) {
                
                // Obtain call back of module whose priority is the highest
                pthread_mutex_lock(&mutex);
                HMDDSDModuleInfo *callBack = self.callBacks.firstObject;
                pthread_mutex_unlock(&mutex);
                if (!callBack) {
                    stop = YES;
                    HMDALOG_PROTOCOL_WARN(@"[HMDDiskSpaceDistribution] call back queue has been empty");
                    break;
                }
                
                BOOL removeSuccessed = NO;
                if (getFreeDiskSpace() < callBack.needSize) {
                    if (callBack.priority >= i) {
                        // All removable files subpackage in small array according to needSize
                        NSArray *filePaths = [self _removableFilePathsFromFiles:files needSize:callBack.needSize];
                        
                        // Remove file by registered instance of module
                        if (moduleRegistered) {
                            if ([module.target respondsToSelector:@selector(removeFileImmediately:)]) {
                                removeSuccessed = [module.target removeFileImmediately:filePaths];
                            }
                            else {
                                HMDALOG_PROTOCOL_WARN(@"[HMDDiskSpaceDistribution] %@ instance dose not respond to [removeFileImmediately:] selector", module.target);
                            }
                        }
                        // Remove file by self
                        else {
                            if (filePaths.count) removeSuccessed = YES;
                            for (NSString *path in filePaths) {
                                if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                                    removeSuccessed = removeSuccessed & [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                                }
                                else {
                                    removeSuccessed = NO;
                                }
                            }
                            HMDALOG_PROTOCOL_INFO(@"[HMDDiskSpaceDistribution] remove files of %@ by self", NSStringFromClass(acls));
                        }
                        NSDictionary *category = @{@"status":@(removeSuccessed), @"priority":@(priority), @"module":NSStringFromClass(acls) ?: @""};
                        NSDictionary *extra = @{@"files":filePaths};
                        HMDALOG_PROTOCOL_INFO(@"[HMDDiskSpaceDistribution] remove file successed or not : %@, files : %@", category, filePaths);
                        [HMDMonitorService trackService:@"slardar_disk_space_free_files" metrics:nil dimension:category extra:extra syncWrite:NO];
                    }
                    //
                    else {
                        stop = YES;
                        BOOL temStop = YES;
                        callBack.block(&temStop, NO);
                        
                        NSDictionary *endCategory = @{@"success":@(0), @"size":@(callBack.needSize), @"priority":@(callBack.priority)};
                        HMDALOG_PROTOCOL_INFO(@"[HMDDiskSpaceDistribution] free end : %@", endCategory);
                        [HMDMonitorService trackService:@"slardar_disk_space_free_end" metrics:nil dimension:endCategory extra:nil syncWrite:YES];
                        
                        pthread_mutex_lock(&mutex);
                        [self.callBacks removeObject:callBack];
                        pthread_mutex_unlock(&mutex);
                        break;
                    }
                }
                else {
                    callBack.callBackDirectlyCount ++;
                    removeSuccessed = YES;
                    HMDALOG_PROTOCOL_INFO(@"[HMDDiskSpaceDistribution] call back directly : %zd", callBack.callBackDirectlyCount);
                }
                
                // Call back after freeing disk
                if (removeSuccessed) {
                    callBack.block(&stop, YES);
                    if (stop || callBack.callBackDirectlyCount > 2) {
                        NSDictionary *endCategory = @{@"success":@(stop), @"size":@(callBack.needSize), @"priority":@(callBack.priority), @"count":@(callBack.callBackDirectlyCount)};
                        HMDALOG_PROTOCOL_INFO(@"[HMDDiskSpaceDistribution] free end : %@", endCategory);
                        [HMDMonitorService trackService:@"slardar_disk_space_free_end" metrics:nil dimension:endCategory extra:nil syncWrite:YES];
                        
                        pthread_mutex_lock(&mutex);
                        [self.callBacks removeObject:callBack];
                        pthread_mutex_unlock(&mutex);
                        break;
                    }
                }
            }
            
            if (stop) break;
        }
        
        if (!stop) {
            size_t freeDisk = getFreeDiskSpace();
            pthread_mutex_lock(&mutex);
            HMDDSDModuleInfo *callBack = self.callBacks.firstObject;
            if (callBack) {
                BOOL moreSpace = NO;
                if (freeDisk > callBack.needSize) moreSpace = YES;
                callBack.block(&stop, moreSpace);
                [self.callBacks removeObject:callBack];
                
                NSDictionary *endCategory = @{@"success":@(stop), @"size":@(callBack.needSize), @"priority":@(callBack.priority)};
                HMDALOG_PROTOCOL_INFO(@"[HMDDiskSpaceDistribution] free end : %@", endCategory);
                [HMDMonitorService trackService:@"slardar_disk_space_free_end" metrics:nil dimension:endCategory extra:nil syncWrite:YES];
            }
            pthread_mutex_unlock(&mutex);
        }
    });
}

#pragma - mark Private

- (NSArray *)_moduleClassFromDefaultModuls {
    NSMutableArray *moduleClass = [NSMutableArray new];
    NSArray *classStringArr = removableFileModules();
    
    if (classStringArr) {
        for (NSString *classStr in classStringArr) {
            Class moduleCls = NSClassFromString(classStr);
            if (moduleCls) {
                [moduleClass hmd_addObject:moduleCls];
            }
        }
    }
    
    return [moduleClass copy];
}

- (void)_addCallBack2PriorityQueue:(HMDDSDModuleInfo *)callBack {
    if (!self.callBacks.count) {
        [self.callBacks hmd_addObject:callBack];
        return;
    }
    
    [self.callBacks enumerateObjectsUsingBlock:^(HMDDSDModuleInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (callBack.priority > obj.priority) {
            [self.callBacks hmd_insertObject:callBack atIndex:idx];
            *stop = YES;
        }
        else if (idx == self.callBacks.count - 1) {
            [self.callBacks hmd_addObject:callBack];
            *stop = YES;
        }
    }];
}

- (NSMutableArray<NSDictionary *> *)_removableFilesFromModule:(Class)module {
    NSMutableArray *files = [NSMutableArray array];
    
    if ([module respondsToSelector:@selector(removableFilePaths)]) {
        NSArray *filePahts = [module removableFilePaths];
        for (NSString *path in filePahts) {
            [files hmd_addObject:@{@"name":path ?: @"",kHMDDiskUsageFileInfoSize:@(2)}];
        }
    }
    else if ([module respondsToSelector:@selector(removableFileDirectoryPath)]) {
        NSString *fileDir = [module removableFileDirectoryPath];
        NSArray *removableFiles = [HMDDiskUsage fetchTopSizeFilesAtPath:fileDir topRank:200];
        if (removableFiles) {
            NSString *rootDir = NSHomeDirectory();
            for (NSDictionary *fileInfo in removableFiles) {
                if ([fileInfo hmd_longLongForKey:kHMDDiskUsageFileInfoSize] > 1) {
                    NSString *filePath = [rootDir stringByAppendingPathComponent:[fileInfo hmd_stringForKey:@"name"]];
                    [files hmd_addObject:@{@"name":filePath,kHMDDiskUsageFileInfoSize:[fileInfo valueForKey:kHMDDiskUsageFileInfoSize] ?: @""}];
                }
            }
        }
    }
    else {
        /*
         Matrix不强制升级，注释此断言
        NSAssert(NO, @"[HMDDiskSpaceDistribution] %@ module dose not implement HMDInspectorDiskSpaceDistribution protocol", NSStringFromClass(module.class));
         */
        HMDALOG_PROTOCOL_FATAL(@"[HMDDiskSpaceDistribution] %@ module dose not implement HMDInspectorDiskSpaceDistribution protocol", NSStringFromClass(module.class));
    }
    
    HMDALOG_PROTOCOL_INFO(@"[HMDDiskSpaceDistribution] module : %@ has %lu files", NSStringFromClass(module), files.count);
    
    return files;
}

- (NSArray <NSString *> *)_removableFilePathsFromFiles:(NSMutableArray<NSDictionary *> *)files needSize:(size_t)size {
    NSMutableArray *pathArr = [NSMutableArray array];
    size_t freeSize = getFreeDiskSpace();
    
    for (NSDictionary *fileInfo in files) {
        NSString *path = [fileInfo hmd_stringForKey:@"name"];
        if (path) {
            freeSize += (double)[fileInfo hmd_longLongForKey:kHMDDiskUsageFileInfoSize];
            [pathArr hmd_addObject:path];
            if ((size_t)freeSize > size) {
                break;
            }
        }
    }
    
    [files removeObjectsInRange:NSMakeRange(0, pathArr.count)];
    return [pathArr copy];
}

static size_t getFreeDiskSpace(void) {
    struct statfs s;
    const char *path = hmd_home_path;
    if (path) {
        int ret = statfs(path, &s);
        if (ret == 0) {
            return s.f_bavail * s.f_bsize;
        }
    }
    return 0;
}
@end
