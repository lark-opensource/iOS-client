//
//  HMDDiskUsage.m
//  Heimdallr
//
//  Created by fengyadong on 2018/1/23.
//

#import "HMDDiskUsage.h"
#import "HMDDiskUsage+Private.h"
#import "HMDMacro.h"
#import "pthread_extended.h"
#include <sys/stat.h>
#include <dirent.h>
#include <sys/mount.h>
#include <stdatomic.h>
#import "HeimdallrUtilities.h"
#import "HMDALogProtocol.h"
#import "NSDictionary+HMDSafe.h"
#import "NSArray+HMDTopN.h"
#import "NSArray+HMDSafe.h"

#define kHMDDiskUsageFindFileRecursionDepthControl 200

NSString *const kHMDDiskUsageFileInfoPath = @"path";
NSString *const kHMDDiskUsageFileInfoSize = @"size";
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
static NSTimeInterval kHMDRecentlyGetFreeDiskSpaceTimestamp = 0;
static NSTimeInterval kHMDRecentlyDiskSpaceCacheTimeInterval = 1.0;
static double kHMDRecentlyGetFreeDiskSpaceByte = 0;

@interface HMDDiskUsage()
@property (nonatomic, strong, readwrite) NSMutableDictionary *outDatedfilesDictionary;
@property (nonatomic, strong, readwrite) NSMutableArray<NSDictionary *> *allFileList;
@property (nonatomic, strong, readwrite) NSMutableArray<NSDictionary *> *abnormalFolders;
// ignoredRelativePathes: While caculate folder size recursively, the file's or folder's size need to ignore
@property (nonatomic, copy, readwrite) NSArray<NSString *> *ignoredRelativePathes;
@property (nonatomic, assign, readwrite) long long folderSpace;
@property (nonatomic, assign, readwrite) NSInteger abnormalFolderSize;
@property (nonatomic, assign, readwrite) NSInteger abnormalFolderFileNumber;
@property (nonatomic, assign, readwrite) double outdatedDays;
// sparse file check: What percentage of "((file'size - file disk size) / (file's size)" is considered to be "sparse file"; (It satisfies both (percentage size) conditions)
@property (nonatomic, assign) double sparseFileLeastDifferPercentage;
// sparse file check: Sparse File is considered a "file'size - file disk size" size
@property (nonatomic, assign) NSUInteger sparseFileLeastDifferSize;
@property (nonatomic, assign) BOOL checkSparseFile;     // default to NO
@property (nonatomic, strong) NSHashTable<id<HMDDiskVisitor>> *visitors;
@property (nonatomic, copy, readwrite) NSString *currenFolderPath;
@property (atomic, assign, readwrite) BOOL isProcessExit;
@property (nonatomic, assign) NSUInteger minCollectSize;
@property (nonatomic, strong) NSMutableSet<NSNumber*> *hardLinkSet;
@property (nonatomic, copy) HMDDiskRecursiveSwitchBlock switchBlock;

@end

@implementation HMDDiskUsage

#pragma mark --- initWithInfo
- (instancetype)initWithOutdatedDays:(double)days
                  abnormalFolderSize:(NSInteger)size
            abnormalFolderFileNumber:(NSInteger)count
                ignoreRelativePathes:(NSArray<NSString *> *)ignoredRelativePathes
                     checkSparseFile:(BOOL)checkSparseFile
     sparseFileLeastDifferPercentage:(double)leastPercentage
           sparseFileLeastDifferSize:(NSUInteger)leastDifferSizeInBytes
                    targetFolderPath:(NSString *)targetFolderPath
                      minCollectSize:(NSUInteger)minCollectSize
                            visitors:(NSHashTable<id<HMDDiskVisitor>> *)visitors
                         switchBlock:(HMDDiskRecursiveSwitchBlock)switchBlock {
    self = [super init];
    if (self) {
        _minCollectSize = minCollectSize;
        _outDatedfilesDictionary = [NSMutableDictionary new];
        _allFileList = [NSMutableArray new];
        _abnormalFolders = [NSMutableArray new];
        _hardLinkSet = [NSMutableSet new];

        if(ignoredRelativePathes == nil) {
           _ignoredRelativePathes = [NSArray array];
        } else {
            [self purifyAndStoreTheIgnorePathes:ignoredRelativePathes]; // allowList: Remove Duplicates path
        }

        /* observe app process exit */
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(currentProcessExit)
                                                    name:UIApplicationWillTerminateNotification
                                                  object:nil];
        __weak typeof(self) weakSelf = self;
        atexit_b(^{
           __strong typeof(self) strongSelf = weakSelf;
           [strongSelf currentProcessExit];
        });

        _minCollectSize = minCollectSize;
        _outdatedDays = days;
        _abnormalFolderFileNumber = count;
        _abnormalFolderSize = size;
        _currenFolderPath = [self translateRelativePathToAbsolute:targetFolderPath];
        if(_currenFolderPath.length > 0 && [_currenFolderPath hasSuffix:@"/"]) {
            _currenFolderPath = [self.currenFolderPath stringByReplacingCharactersInRange:NSMakeRange(self.currenFolderPath.length - 1, 1) withString:@""];
        }

        _checkSparseFile = checkSparseFile;
        leastPercentage = MIN(leastPercentage, 1.0);
        leastPercentage = MAX(leastPercentage, 0);
        _sparseFileLeastDifferPercentage = leastPercentage;
        _sparseFileLeastDifferSize = leastDifferSizeInBytes;
        _visitors = visitors;
        _switchBlock = switchBlock;
        
        BOOL isAbnormal = NO;
        BOOL isOutdated = YES;
        if (!HMDIsEmptyString(_currenFolderPath)) {
            const char *folderPath = [_currenFolderPath cStringUsingEncoding:NSUTF8StringEncoding];
            _folderSpace = [self recursiveCalculateAtPath:folderPath
                                                   isAbnormal:&isAbnormal
                                                   isOutdated:&isOutdated
                                          needCheckIgnorePath:YES
                                                   depthLevel:0];
        }

    }

    return self;
}

- (instancetype)initWithOutdatedDays:(double)days
                  abnormalFolderSize:(NSInteger)size
            abnormalFolderFileNumber:(NSInteger)count
                ignoreRelativePathes:(NSArray<NSString *> *)ignoredRelativePathes
                     checkSparseFile:(BOOL)checkSparseFile
     sparseFileLeastDifferPercentage:(double)leastPercentage
           sparseFileLeastDifferSize:(NSUInteger)leastDifferSizeInBytes
                    targetFolderPath:(NSString *)targetFolderPath
                      minCollectSize:(NSUInteger)minCollectSize
                            visitors:(NSHashTable<id<HMDDiskVisitor>> *)visitors {
    return [self initWithOutdatedDays:days
                   abnormalFolderSize:size
             abnormalFolderFileNumber:count
                 ignoreRelativePathes:ignoredRelativePathes
                      checkSparseFile:checkSparseFile
      sparseFileLeastDifferPercentage:leastPercentage
            sparseFileLeastDifferSize:leastDifferSizeInBytes
                     targetFolderPath:targetFolderPath
                       minCollectSize:minCollectSize
                             visitors:visitors
                          switchBlock:nil];
    
}

- (instancetype)initWithOutdatedDays:(double)days
                  abnormalFolderSize:(NSInteger)size
            abnormalFolderFileNumber:(NSInteger)count
                ignoreRelativePathes:(NSArray<NSString *> *)ignoredRelativePathes
                     checkSparseFile:(BOOL)checkSparseFile
     sparseFileLeastDifferPercentage:(double)leastPercentage
           sparseFileLeastDifferSize:(NSUInteger)leastDifferSizeInBytes
                      minCollectSize:(NSUInteger)minCollectSize
                            visitors:(NSHashTable<id<HMDDiskVisitor>> *)visitors
{
    return [self initWithOutdatedDays:days
                   abnormalFolderSize:size
             abnormalFolderFileNumber:count
                 ignoreRelativePathes:ignoredRelativePathes
                      checkSparseFile:checkSparseFile
      sparseFileLeastDifferPercentage:leastPercentage
            sparseFileLeastDifferSize:leastDifferSizeInBytes
                     targetFolderPath:@""
                       minCollectSize:minCollectSize
                             visitors:visitors];
}

- (instancetype)initWithOutdatedDays:(double)days
                  abnormalFolderSize:(NSInteger)size
            abnormalFolderFileNumber:(NSInteger)count
                ignoreRelativePathes:(NSArray<NSString *> *)ignoredRelativePathes
                     checkSparseFile:(BOOL)checkSparseFile
     sparseFileLeastDifferPercentage:(double)leastPercentage
           sparseFileLeastDifferSize:(NSUInteger)leastDifferSizeInBytes
                            visitors:(NSHashTable<id<HMDDiskVisitor>> *)visitors {
    return [self initWithOutdatedDays:days
                     abnormalFolderSize:size
               abnormalFolderFileNumber:count
                   ignoreRelativePathes:ignoredRelativePathes
                        checkSparseFile:checkSparseFile
        sparseFileLeastDifferPercentage:leastPercentage
              sparseFileLeastDifferSize:leastDifferSizeInBytes
                       targetFolderPath:@""
                       minCollectSize:0
                               visitors:visitors];
}

- (instancetype)initWithOutdatedDays:(double)days
                  abnormalFolderSize:(NSInteger)size
            abnormalFolderFileNumber:(NSInteger)count
                ignoreRelativePathes:(NSArray<NSString *> *)ignoredRelativePathes
                     checkSparseFile:(BOOL)checkSparseFile
     sparseFileLeastDifferPercentage:(double)leastPercentage
           sparseFileLeastDifferSize:(NSUInteger)leastDifferSizeInBytes {
    return [self initWithOutdatedDays:days
                     abnormalFolderSize:size
               abnormalFolderFileNumber:count
                   ignoreRelativePathes:ignoredRelativePathes
                        checkSparseFile:checkSparseFile
        sparseFileLeastDifferPercentage:leastPercentage
              sparseFileLeastDifferSize:leastDifferSizeInBytes
                               visitors:nil];
}

- (instancetype)init {
    return [self initWithOutdatedDays:0
                     abnormalFolderSize:0
               abnormalFolderFileNumber:0
                   ignoreRelativePathes:nil
                        checkSparseFile:NO
        sparseFileLeastDifferPercentage:0
              sparseFileLeastDifferSize:0];
}

- (instancetype)initWithFolderPath:(NSString *)folderPath {
    return [self initWithFolderPath:folderPath switchBlock:nil];
}

- (instancetype)initWithFolderPath:(NSString *)folderPath switchBlock:(HMDDiskRecursiveSwitchBlock)block{
    return [self initWithOutdatedDays:0
                   abnormalFolderSize:0
             abnormalFolderFileNumber:0
                 ignoreRelativePathes:nil
                      checkSparseFile:NO
      sparseFileLeastDifferPercentage:0
            sparseFileLeastDifferSize:0
                     targetFolderPath:folderPath
                       minCollectSize:0
                             visitors:nil
                          switchBlock:block];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark --- protect process exit
- (BOOL)isAbnormalReturnValue {
    return self.isProcessExit;
}

- (void)currentProcessExit {
    self.isProcessExit = YES;
}

#pragma mark --- compliance public method
+ (int)getTotalDiskSizeLevel {
    double totalSize = [HMDDiskUsage getTotalDiskSpace];
    if (totalSize <= 16 * HMD_GB) {
        return 0;
    } else if (totalSize <= 32 * HMD_GB) {
        return 1;
    } else if (totalSize <= 64 * HMD_GB) {
        return 2;
    } else if (totalSize <= 128 * HMD_GB) {
        return 3;
    } else if (totalSize <= 256 * HMD_GB) {
        return 4;
    } else if (totalSize <= 512 * HMD_GB) {
        return 5;
    } else {
        return 6;
    }
}

+ (NSInteger)getFreeDisk300MBlockSizeWithWaitTime:(NSTimeInterval)waitTime {
    double totalSize = [HMDDiskUsage getFreeDiskSpaceWithWaitTime:waitTime];
    NSInteger blockSize = ceil(totalSize / (300 * HMD_MB));
    return blockSize;
}

+ (NSInteger)getFreeDisk300MBlockSize {
    double totalSize = [HMDDiskUsage getFreeDiskSpace];
    NSInteger blockSize = ceil(totalSize / (300 * HMD_MB));
    return blockSize;
}

+ (NSInteger)getFreeDisk300MBlockSizeByStatf {
    size_t totalSize = [HMDDiskUsage getFreeDiskSpaceByStatf];
    NSInteger blockSize = (NSInteger)(ceil(totalSize / (300 * HMD_MB)));
    return blockSize;
}

+ (NSInteger)getRecentCachedFreeDisk300MBlockSize {
    double totalSize = [HMDDiskUsage getRecentCachedFreeDiskSpace];
    NSInteger blockSize = (NSInteger)(ceil(totalSize / (300 * HMD_MB)));
    return blockSize;
}

+ (NSInteger)getDisk300MBBlocksFrom:(NSInteger)oriSize {
    NSInteger blockSize = (NSInteger)(ceil(oriSize / (300 * HMD_MB)));
    return blockSize;
}

#pragma mark --- public Method
+ (double)getTotalDiskSpace {
    static double totalSpace = 0;
    if (totalSpace == 0) {
        NSError *error;
        NSDictionary *infoDic = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error: &error];
        if (infoDic) {
            NSNumber *fileSystemSizeInBytes = [infoDic objectForKey:NSFileSystemSize];
            totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        }
    }
    return totalSpace;
}

+ (void)setFreeDiskSpaceCacheTimeInterval:(NSTimeInterval)cacheTimeInterval {
    kHMDRecentlyDiskSpaceCacheTimeInterval = kHMDRecentlyDiskSpaceCacheTimeInterval > cacheTimeInterval ? : cacheTimeInterval;
}

+ (double)getRecentCachedFreeDiskSpace {
    NSTimeInterval nowTimestamp = [[NSDate date] timeIntervalSince1970];
    if (((nowTimestamp - kHMDRecentlyGetFreeDiskSpaceTimestamp) < kHMDRecentlyDiskSpaceCacheTimeInterval) &&
        kHMDRecentlyGetFreeDiskSpaceByte > 0.0) {
        return kHMDRecentlyGetFreeDiskSpaceByte;
    } else {
        return [[self class] getFreeDiskSpace];
    }
}

+ (double)getFreeDiskSpaceWithWaitTime:(NSTimeInterval)waitTime {
    if ([NSThread isMainThread]) {
        static atomic_flag waitFlag = ATOMIC_FLAG_INIT;
        if (atomic_flag_test_and_set_explicit(&waitFlag, memory_order_relaxed)) {
            return kHMDRecentlyGetFreeDiskSpaceByte;
        }
        dispatch_block_t block = dispatch_block_create(0, ^{
            [self getFreeDiskSpace];
            atomic_flag_clear_explicit(&waitFlag, memory_order_release);
        });
        dispatch_queue_t queue = dispatch_queue_create("com.heimdallr.diskusage_protect", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos_class_self(), 0));
        dispatch_async(queue, block);
        dispatch_block_wait(block, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)));

        return kHMDRecentlyGetFreeDiskSpaceByte;
    } else {
        return [self getFreeDiskSpace];
    }
}

+ (double)getFreeDiskSpace {
    if (@available(iOS 11.0, *)) {
        NSError *error = nil;
        NSURL *fileURL = [NSURL fileURLWithPath:NSHomeDirectory()];
        NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:&error];
        if (!error && results) {
            NSNumber *freeDisk = [results valueForKey:NSURLVolumeAvailableCapacityForImportantUsageKey];
            double freeDiskSpace = [freeDisk doubleValue];
            kHMDRecentlyGetFreeDiskSpaceByte = freeDiskSpace;
            kHMDRecentlyGetFreeDiskSpaceTimestamp = [[NSDate date] timeIntervalSince1970];
            return freeDiskSpace;
        } else {
            if (hmd_log_enable()) {
                HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"[HMDDiskUsage getFreeDiskSpace] failed with error: %@", error);
            }
            return 0;
        }
    } else {
        NSError *error = nil;
        NSDictionary *informationDictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error: &error];
        if (!error && informationDictionary) {

            NSNumber *fileSystemSizeInBytes = [informationDictionary objectForKey:NSFileSystemFreeSize];
            double freeDiskSpace = [fileSystemSizeInBytes doubleValue];
            kHMDRecentlyGetFreeDiskSpaceByte = freeDiskSpace;
            kHMDRecentlyGetFreeDiskSpaceTimestamp = [[NSDate date] timeIntervalSince1970];
           return freeDiskSpace;
        } else {
           if (hmd_log_enable()) {
               HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"[HMDDiskUsage getFreeDiskSpace] failed with error: %@", error);
           }
           return 0;
        }
    }
}

+ (size_t)getFreeDiskSpaceByStatf {
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

+ (unsigned long long)folderSizeAtPath:(NSString *)folderPath {
    HMDDiskUsage *diskUsage = [[HMDDiskUsage alloc] initWithFolderPath:folderPath switchBlock:nil];
    return diskUsage.folderSpace;
}

+ (unsigned long long)folderSizeAtPath:(NSString *)folderPath switchBlock:(HMDDiskRecursiveSwitchBlock _Nullable)block{
    HMDDiskUsage *diskUsage = [[HMDDiskUsage alloc] initWithFolderPath:folderPath switchBlock:block];
    return diskUsage.folderSpace;
}

+ (unsigned long long)folderSizeAtPath:(NSString *)folderPath visitor:(id<HMDDiskVisitor>)visitor {
    if (visitor == nil) {
        return [HMDDiskUsage folderSizeAtPath:folderPath];
    }
    NSHashTable *visitors = [NSHashTable weakObjectsHashTable];
    [visitors addObject:visitor];
    HMDDiskUsage *diskUsage = [[HMDDiskUsage alloc] initWithOutdatedDays:0
                                                      abnormalFolderSize:0
                                                abnormalFolderFileNumber:0
                                                    ignoreRelativePathes:nil
                                                         checkSparseFile:NO
                                         sparseFileLeastDifferPercentage:0
                                               sparseFileLeastDifferSize:0
                                                        targetFolderPath:folderPath
                                                          minCollectSize:0
                                                                visitors:visitors];
    return diskUsage.folderSpace;
}

+ (unsigned long long)folderSizeAtPath:(NSString *)folderPath visitor:(id<HMDDiskVisitor>)visitor switchBlock:(HMDDiskRecursiveSwitchBlock)block {
    if (visitor == nil) {
        return [self folderSizeAtPath:folderPath switchBlock:block];
    }
    NSHashTable *visitors = [NSHashTable weakObjectsHashTable];
    [visitors addObject:visitor];
    HMDDiskUsage *diskUsage = [[HMDDiskUsage alloc] initWithOutdatedDays:0
                                                      abnormalFolderSize:0
                                                abnormalFolderFileNumber:0
                                                    ignoreRelativePathes:nil
                                                         checkSparseFile:NO
                                         sparseFileLeastDifferPercentage:0
                                               sparseFileLeastDifferSize:0
                                                        targetFolderPath:folderPath
                                                          minCollectSize:0
                                                                visitors:visitors
                                                             switchBlock:block];
    return diskUsage.folderSpace;
}

- (double)getThisAppSpace {
    NSString *homeDirectory = [self getAPPHomeDirectory];
    if (![self.currenFolderPath isEqualToString:homeDirectory]) {
        BOOL isAbnormal = NO;
        BOOL isOutdated = YES;
        return [self folderSizeAtPath:homeDirectory isAbnormal:&isAbnormal isOutdated:&isOutdated];
    }
    return self.folderSpace;
}

- (long long)getCurrenFolderSpace {
    return self.folderSpace;
}

- (unsigned long long)fileSizeAtPath:(NSString *)filePath {
    struct stat st;
    if(lstat([filePath cStringUsingEncoding:NSUTF8StringEncoding], &st) == 0){
        return st.st_size;
    }
    return 0;
}

+ (NSArray<NSDictionary *> *)fetchTopSizeFilesAtPath:(NSString *)path topRank:(NSUInteger)topRank {
    if(path && path.length > 0 && [path hasSuffix:@"/"]) {
        path = [path stringByReplacingCharactersInRange:NSMakeRange(path.length - 1, 1) withString:@""];
    }

    HMDDiskUsage *usage = [[HMDDiskUsage alloc] initWithFolderPath:path?:@""];
    NSArray *sortedFiles = [usage getCurrentFileListForTopRank:topRank];
    return [sortedFiles copy];
}

#pragma mark - get folder size
- (unsigned long long)folderSizeAtPath:(NSString *)folderPath isAbnormal:(BOOL *)isAbnormal isOutdated:(BOOL *)isOutdated {
    if(folderPath && folderPath.length > 0 && [folderPath hasSuffix:@"/"]) {
        folderPath = [folderPath stringByReplacingCharactersInRange:NSMakeRange(folderPath.length - 1, 1) withString:@""];
    }
    if ([folderPath isEqualToString:self.currenFolderPath]) {
        return self.folderSpace;
    }
    return [self recursiveCalculateAtPath:[folderPath cStringUsingEncoding:NSUTF8StringEncoding]
                               isAbnormal:isAbnormal
                               isOutdated:isOutdated
                      needCheckIgnorePath:NO];
}

#pragma mark - get fileSize Use C
/**
 Recursive caculate the folder size and store the information.
 needCheckIgnorePath: Is need check that 'self.ignoreRelativePathes'  include current folder of file path.
 If value is YES,  use 'self.ignoredRelativePathes'  tests whether the current path to belong to self.ignoredRelativePathes;
 if belong to, ignore all files under the current path, by justing returning zero
 and if not, continue to testing by recursive  whether current folder's file or folder's path belong toself.ignoredRelativePathes;

 @param folderPath This path must not end with '/' character
 @param isAbnormal is abnormal file
 @param isOutdated is out  date folder
 @param needCheckIgnorePath  Is need check that 'self.ignoreRelativePathes'  include current folder of file path.
 @return size for current folder
 */
- (long long)recursiveCalculateAtPath:(const char *)folderPath
                           isAbnormal:(BOOL *)isAbnormal
                           isOutdated:(BOOL *)isOutdated
                  needCheckIgnorePath:(BOOL)needCheckIgnorePath {
     return [self recursiveCalculateAtPath:folderPath
                                isAbnormal:isAbnormal
                                isOutdated:isOutdated
                       needCheckIgnorePath:needCheckIgnorePath
                                depthLevel:0];
}

- (long long)recursiveCalculateAtPath:(const char *)folderPath
                           isAbnormal:(BOOL *)isAbnormal
                           isOutdated:(BOOL *)isOutdated
                  needCheckIgnorePath:(BOOL)needCheckIgnorePath
                            depthLevel:(NSUInteger)depthLevel
{
    if (self.isProcessExit) { return 0; }
    if (self.switchBlock && self.switchBlock()) { return 0; }
    // limited recursion to avoid stack overflow
    if (depthLevel > kHMDDiskUsageFindFileRecursionDepthControl) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"RecursiveCalculateAtPath avoid stack overflow, folderPath: %s", folderPath);
        }
        return 0;
    }

    // It's essentially the same as stringWithUTF8String, but it saves one step of 'strlen'
    size_t folderPathLength = strlen(folderPath);
    if (folderPathLength == 0) { return 0; }
    if (folderPathLength > FILENAME_MAX) { // avoid file name length out of FILENAME_MAX;
      if (hmd_log_enable()) {
          HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Disk folder or file name out of FILENAME_MAX, length: %ld, path: %s", folderPathLength, folderPath);
      }
      return 0;
    }

    NSString *foldPathString = [[NSString alloc] initWithBytes:folderPath length:folderPathLength encoding:NSUTF8StringEncoding];
    if(foldPathString == nil) { return 0; }

    // needCheckIgnorePath checking current folder path belong tp self.needCheckIgnorePath
    if(needCheckIgnorePath) {
        NSString *currentAbsolutePath = foldPathString;
        if(currentAbsolutePath != nil) {
            needCheckIgnorePath = NO;
            for(NSString *eachRelativeIgnorePath in self.ignoredRelativePathes) {
                NSString *eachAsoluteIgnorePath = [self translateRelativePathToAbsolute:eachRelativeIgnorePath];
                if([currentAbsolutePath hasPrefix:eachAsoluteIgnorePath]) {
                    return 0; // Igonrance happened here
                } else if ([eachAsoluteIgnorePath hasPrefix:currentAbsolutePath]) {
                    needCheckIgnorePath = YES;
                }
            }
        }
    }
    // end checking current folder path belong tp self.needCheckIgnorePath

    long long folderSize = 0;
    DIR *dir = opendir(folderPath);
    if (dir == NULL) { return 0; }
    struct dirent* subfile;
    NSMutableArray *allSubfilePaths = [NSMutableArray new];
    while ((subfile = readdir(dir))!=NULL) {
        @autoreleasepool {
            if (subfile->d_type == DT_DIR &&
                ((subfile->d_name[0] == '.' && subfile->d_name[1] == 0) ||
                 (subfile->d_name[0] == '.' && subfile->d_name[1] == '.' && subfile->d_name[2] == 0))) {
                continue; // ignore folder: ./ ../
            }
            char subfilePath[FILENAME_MAX];
            // copy folderPath => subfilePath
            strncpy(subfilePath, folderPath, sizeof(subfilePath) - 1);
            subfilePath[sizeof(subfilePath) - 1] = '\0';

            // Judge folderPathLength == subfilePathLength
            // subfilePath append '/'
            size_t currentPathLength = strlen(subfilePath);
            if(currentPathLength == folderPathLength && currentPathLength < sizeof(subfilePath) - 2) {
                if (folderPath[folderPathLength - 1] != '/'){
                    subfilePath[currentPathLength++] = '/';
                    subfilePath[currentPathLength] = '\0';
                }
            }
            else {
                NSAssert(NO,
                         @"[LOGICAL ERROR] Please preserve current application environment, and contact Heimdallr developer ASAP");
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDDiskUsage recursiveCalculateAtPath:%s isAbnormal:isOutdated:needCheckIgnorePath:] subfilepath %s exceed FILENAME_MAX", folderPath, subfile->d_name);
                continue;
            }

            char *subfileAppendPointer = subfilePath + currentPathLength;
            size_t subfilePathRemainSize = sizeof(subfilePath) - currentPathLength;   // included '\0' space

            // MIN(subfilePathRemainSize) == 1
            if(subfilePathRemainSize < strlen(subfile->d_name) + 1) {
                // It's impossible appear out of length  MAX(subfilePathLength) == sizeof(subfilePath) - 1
                NSAssert(NO,
                         @"[LOGICAL EOOR] Please preserve current application environment, and contact Heimdallr developer ASAP");
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDDiskUsage recursiveCalculateAtPath:%s"
                                           "isAbnormal:isOutdated:needCheckIgnorePath:] subfilePath %s exceed FILENAME_MAX", subfilePath, subfile->d_name);
                continue;
            }

            // use secure function to append subfilePath
            strncpy(subfileAppendPointer, subfile->d_name, subfilePathRemainSize - 1);
            subfileAppendPointer[subfilePathRemainSize - 1] = '\0';

            NSString *subfilePathString = [NSString stringWithUTF8String:subfilePath];

            if(subfilePathString == nil) {
                NSAssert(NO,
                         @"[LOGICAL EOOR] Please preserve current application environment, and contact Heimdallr developer ASAP");
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDDiskUsage recursiveCalculateAtPath:%s"
                                          "isAbnormal:isOutdated:needCheckIgnorePath:] subfilePath %s exceed FILENAME_MAX", subfilePath, subfile->d_name);
                continue;
            }

            [allSubfilePaths addObject:subfilePathString];

            long long fileSize = 0;
            if (subfile->d_type == DT_DIR){ // directory
                BOOL currentAbnormal = NO;
                BOOL currentOutdated = YES;
                // calculate sub directory size by recursive call
                fileSize = [self recursiveCalculateAtPath:subfilePath
                                               isAbnormal:&currentAbnormal
                                               isOutdated:&currentOutdated
                                      needCheckIgnorePath:needCheckIgnorePath
                                               depthLevel:(depthLevel+1)];

                folderSize += fileSize;
                //sub file is abnormal file，it's parent directory must be abnormal
                *isAbnormal |= currentAbnormal;
                *isOutdated &= currentOutdated;
                // add the space taken up by the directory itself
                struct stat st;
                if(lstat(subfilePath, &st) == 0) {
                    folderSize += st.st_size;
                }
            } else if (subfile->d_type == DT_REG || subfile->d_type == DT_LNK)   { // file or link
                struct stat st;
                if(lstat(subfilePath, &st) == 0) {

                    fileSize = st.st_size;
                    // filter hard link inode
                    if (st.st_nlink > 1) {
                        if ([self.hardLinkSet containsObject:@(st.st_ino)]) {
                            fileSize = 0;
                        }else {
                            [self.hardLinkSet addObject:@(st.st_ino)];
                        }
                    }
                    // check sparse file
                    if(self.checkSparseFile &&
                       fileSize >= self.sparseFileLeastDifferSize) {
                        long long currentFileSize = fileSize;
                        long long currentDiskSize = st.st_blocks * st.st_blksize;
                        // check the difference between real disk usage and file size out of sparse file check threshold
                        BOOL isDiffOutOfThreshold = self.sparseFileLeastDifferSize > 0 ? ((currentFileSize - currentDiskSize) >= ((long long)self.sparseFileLeastDifferSize)) : NO;
                        BOOL isScaleOutOfThreshold = self.sparseFileLeastDifferPercentage > 0 ? (((currentFileSize - currentDiskSize) / (long double)currentFileSize) >= self.sparseFileLeastDifferPercentage) : NO;
                        if ( isDiffOutOfThreshold && isScaleOutOfThreshold) {
                            fileSize = currentDiskSize;    // sparse 文件判断逻辑
                        }
                    }

                    folderSize += fileSize;
                    // record current file's size
                    [self calculateTopFiles:subfilePathString fileSize:fileSize];
                    BOOL currentOutdated = YES;
                    // Whether the file is expired
                    __auto_type lastAccessdate = [self calculateOutDateFilesAtPath:subfilePath fileSize:fileSize isOutdated:&currentOutdated fileCount:1];
                    *isOutdated &= currentOutdated;
                    if (self.visitors) {
                        for (id<HMDDiskVisitor> visitor in self.visitors) {
                            if ([visitor respondsToSelector:@selector(visitFile:size:lastAccessDate:)]) {
                                // copy path string avoid visitor change path string
                                [visitor visitFile:[subfilePathString copy] size:fileSize lastAccessDate:lastAccessdate];
                            }
                            if ([visitor respondsToSelector:@selector(visitFile:size:lastAccessDate:deepLevel:)]) {
                                [visitor visitFile:[subfilePathString copy] size:fileSize lastAccessDate:lastAccessdate deepLevel:(depthLevel + 1)];
                            }
                        }
                    }
                }
            }
        }
    }
    closedir(dir);

    // Whether the folder is abnormal folder
    NSUInteger fileCount = 0;
    if (allSubfilePaths.count > 0) {
        [self calculateExceptionFilesAtFolderPath:folderPath folderSize:folderSize isAbnormal:isAbnormal fileCount:&fileCount];
    }

    // Whether the file is expired
    NSDate *lastAccessDate = nil;
    if (*isOutdated) {
        // If current folder is expired, need to remove all the expired subfiles that is recorded by 'self.outDatedfilesDictionary' in that folder
        lastAccessDate = [self calculateOutDateFilesAtPath:folderPath fileSize:folderSize isOutdated:isOutdated fileCount:allSubfilePaths.count];
        for (NSString *subFilePath in allSubfilePaths) {
            [self.outDatedfilesDictionary removeObjectForKey:subFilePath];
        }
    }
    else {
        lastAccessDate = [self getFileAccessLastDateAtPath:foldPathString];
    }

    if (self.visitors) {
        for (id<HMDDiskVisitor> visitor in self.visitors) {
            if ([visitor respondsToSelector:@selector(visitDirectory:size:fileCount:lastAccessDate:)]) {
                // copy path string avoid visitor to change path string
                [visitor visitDirectory:[foldPathString copy] size:folderSize fileCount:fileCount lastAccessDate:lastAccessDate];
            }
            if ([visitor respondsToSelector:@selector(visitDirectory:size:deepLevel:)]) {
                [visitor visitDirectory:[foldPathString copy] size:folderSize deepLevel:depthLevel];
            }
        }
    }

    return folderSize;
}
#pragma mark - get exception folder
- (void)calculateExceptionFilesAtFolderPath:(const char *)filePath folderSize:(long long)fileSize isAbnormal:(BOOL *)isAbnormal fileCount:(NSUInteger *)count{
    if (self.abnormalFolderSize == 0 && self.abnormalFolderFileNumber == 0) {
        return;
    }

    NSString *path = [NSString stringWithUTF8String:filePath];
    NSAssert(path.length != 0, @"ERROR: path.length == ZERO cause CRASH");
    if(path.length == 0) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"- [HMDDiskUsage calculateExceptionFilesAtFolderPath:%s] empty string", filePath);
        return;
    };

    NSArray *filelist= [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSInteger fileCount = [filelist count];
    NSString *relativePath = [self translateAbsolutePathToRelative:path];
    *count = fileCount;
    if ((self.abnormalFolderSize && fileSize > self.abnormalFolderSize) ||
        (self.abnormalFolderFileNumber && fileCount > self.abnormalFolderFileNumber)) {
        //Only the deepest exception folders are recorded
        if (*isAbnormal) {
            return;
        }
        *isAbnormal = YES;
        // if relativePath is nil, record the path as 'ErrorPath'
        if (relativePath == nil && hmd_log_enable()) {
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"[HMDDiskUsage calculateExceptionFilesAtFolderPath] relative path nil: %@", path);
        }
        NSDictionary *dict = @{@"name":relativePath?:@"ErrorPath",
                               @"size":@(fileSize),
                               @"num":@(fileCount)
                               };
        [self.abnormalFolders hmd_addObject:dict];
    }
}
- (NSArray<NSDictionary *> *)getExceptionFolders {
    return self.abnormalFolders;
}

- (NSArray<NSDictionary *> *)getExceptionFoldersWithTopRank:(NSInteger)topRank {
    if (topRank <= 0) { return @[]; }
    NSArray<NSDictionary *> *topNArray = [NSArray hmd_heapTopNWithArray:self.abnormalFolders topN:topRank usingComparator:^NSComparisonResult(NSDictionary *  _Nonnull obj1, NSDictionary *  _Nonnull obj2) {
        return [obj1 hmd_longLongForKey:@"size"] > [obj2 hmd_longLongForKey:@"size"] ? NSOrderedDescending :NSOrderedAscending ;
    }];
    return [topNArray copy];
}

#pragma mark - get top files
- (void)calculateTopFiles:(NSString *)filePath fileSize:(long long)fileSize {
    if (filePath.length > 0 && fileSize > self.minCollectSize) {
        NSString *relativePath = [self translateAbsolutePathToRelative:filePath];
        if(relativePath != nil) {
            NSDictionary *dict = @{@"name":relativePath,@"size":@(fileSize)};
            [self.allFileList hmd_addObject:dict];
        }
    }
}

- (NSArray<NSDictionary *> *)getFileListsAtPath:(NSString *)folderPath forTopRank:(NSUInteger)topRank {
    NSString *absolutePath = [self translateRelativePathToAbsolute:folderPath];
    if(absolutePath && absolutePath.length > 0 && [absolutePath hasSuffix:@"/"]) {
        absolutePath = [absolutePath stringByReplacingCharactersInRange:NSMakeRange(absolutePath.length - 1, 1) withString:@""];
    }

    if (![absolutePath isEqualToString:self.currenFolderPath]) {
        pthread_mutex_lock(&mutex);
        self.currenFolderPath = absolutePath;
        [_outDatedfilesDictionary removeAllObjects];
        [_allFileList removeAllObjects];
        [_abnormalFolders removeAllObjects];
        if (!HMDIsEmptyString(self.currenFolderPath)) {
            BOOL isAbnormal = NO;
            BOOL isOutdated = YES;
            const char *folderPath = [self.currenFolderPath cStringUsingEncoding:NSUTF8StringEncoding];
            self.folderSpace = [self recursiveCalculateAtPath:folderPath isAbnormal:&isAbnormal isOutdated:&isOutdated needCheckIgnorePath:YES];
        }
        pthread_mutex_unlock(&mutex);
    }

    return [self getCurrentFileListForTopRank:topRank];
}

- (NSArray<NSDictionary *> *)getCurrentFileListForTopRank:(NSUInteger)topRank {
    if (topRank <= 0) { return @[]; }
    NSArray<NSDictionary *> *topNArray = [NSArray hmd_heapTopNWithArray:self.allFileList topN:topRank usingComparator:^NSComparisonResult(NSDictionary *  _Nonnull obj1, NSDictionary *  _Nonnull obj2) {
        return [obj1 hmd_longLongForKey:@"size"] > [obj2 hmd_longLongForKey:@"size"] ? NSOrderedDescending :NSOrderedAscending ;
    }];

    return [topNArray copy];
}

- (NSArray<NSDictionary *> *)getAppFileListForTopRank:(NSUInteger)topRank {
    NSString * dirPath = @""; // relative path
    return [self getFileListsAtPath:dirPath forTopRank:topRank];
}

#pragma mark - get outdated files
- (NSDate *)calculateOutDateFilesAtPath:(const char *)filePath fileSize:(long long)fileSize isOutdated:(BOOL *)isOutdated fileCount:(NSInteger)fileCount {
    if (!filePath ) {
        return nil;
    }

    NSString *path = [NSString stringWithUTF8String:filePath];
    if(path == nil) return nil;
    NSDate *lastAccessDate = [self getFileAccessLastDateAtPath:path];
    if (!self.outdatedDays) {
        return lastAccessDate;
    }

    NSTimeInterval interval = self.outdatedDays * 24 * 3600;
    *isOutdated = ([lastAccessDate timeIntervalSince1970] + interval) < [[NSDate date] timeIntervalSince1970];
    if (*isOutdated) {
        NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] - [lastAccessDate timeIntervalSince1970];
        NSString *relativePath = [self translateAbsolutePathToRelative:path];
        NSMutableDictionary *dict = [NSMutableDictionary new];
        if (relativePath) {
            [dict hmd_setObject:relativePath forKey:@"name"];
            [dict setObject:@(MilliSecond(interval)) forKey:@"outdate_interval"];
            [dict setObject:@(fileCount) forKey:@"num"];
            [dict setObject:@(fileSize) forKey:@"size"];

            [self.outDatedfilesDictionary setObject:dict forKey:path];
        }
    }
    return lastAccessDate;
}

- (NSArray<NSDictionary *> *)getOutDateFiles {
    return self.outDatedfilesDictionary.allValues;
}

- (NSArray<NSDictionary *> *)getOutDateFilesWithTopRank:(NSInteger)topRank {
    if (topRank <= 0) { return @[]; }
    NSArray *outdatedFiles = self.outDatedfilesDictionary.allValues;
    NSArray *topNOutdateFiles = [NSArray hmd_heapTopNWithArray:outdatedFiles topN:topRank usingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [obj1 hmd_longLongForKey:@"outdate_interval"] > [obj2 hmd_longLongForKey:@"outdate_interval"] ? NSOrderedDescending : NSOrderedAscending;
    }];
    return [topNOutdateFiles copy];
}

#pragma mark - ignoredRelativePathes property method override

// purifyAndStoreTheIgnorePathes:
// optimize ignoredRelativePathes, if there are two paths,the long path is contained by the short path(or repeated path), the long path will be removed;
- (void)purifyAndStoreTheIgnorePathes:(NSArray<NSString *> *)ignoredRelativePathes {
    NSUInteger unsortedPathsCount = ignoredRelativePathes.count;

    NSMutableArray<NSString *> *cutHeaderAndTrail = [NSMutableArray arrayWithCapacity:unsortedPathsCount];
    for(NSUInteger index = 0; index < unsortedPathsCount; index++) {
        NSString *current = ignoredRelativePathes[index];
        if (current.length > 0) {
            if([current hasPrefix:@"/"]){
                current = [current stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
            }
            if([current hasSuffix:@"/"]){
                current = [current stringByReplacingCharactersInRange:NSMakeRange(current.length - 1, 1) withString:@""];
            }
            if(![current hasPrefix:@"/"] && ![current hasSuffix:@"/"]) {
                [cutHeaderAndTrail addObject:current];
            }
        }
    }

    NSMutableArray *unsortedPaths = [NSMutableArray arrayWithArray:cutHeaderAndTrail];
    [unsortedPaths sortUsingComparator:^NSComparisonResult (NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
        return [obj1 compare:obj2 options:NSLiteralSearch];
    }];

    NSMutableArray<NSString *> *sortedPathes = [NSMutableArray array];

    for(NSUInteger index = 0; index < unsortedPathsCount ; index++) {
        NSUInteger sameRangeIndex = index;
        while(sameRangeIndex + 1 < unsortedPathsCount)
            if([unsortedPaths[sameRangeIndex + 1] hasPrefix:unsortedPaths[index]])
                sameRangeIndex++;
            else break;
        [sortedPathes addObject:unsortedPaths[index]];
        index = sameRangeIndex;
    }
    self.ignoredRelativePathes = sortedPathes;
}

#pragma mark - Tool

- (NSString *)translateAbsolutePathToRelative:(NSString *)absolutePath {
    NSAssert(absolutePath != nil, @"[HMDDiskUsage translateAbsolutePathToRelative:] nil path");
    if(absolutePath == nil) return nil;
    NSString * basePath = [self getAPPHomeDirectory];
    if ([absolutePath containsString:basePath] && absolutePath.length > basePath.length) {
        NSString *relativePath = [absolutePath substringFromIndex:basePath.length];
        return relativePath;
    }
    return nil;
}

- (NSString *)getAPPHomeDirectory {
    static NSString *homeDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        homeDirectory = NSHomeDirectory();
    });
    return homeDirectory;
}

- (NSString *)getAPPBundlePath {
    static NSString *bundlePath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundlePath = [[NSBundle mainBundle] bundlePath];
    });
    return bundlePath;
}

- (NSString *)translateRelativePathToAbsolute:(NSString *)relativePath {
    NSAssert(relativePath != nil, @"[HMDDiskUsage TranslateRelativePathToAbsolute:] nil path");
    NSString *homeDirectory = [self getAPPHomeDirectory];
    if(relativePath == nil) { return homeDirectory; }
    if ([relativePath hasPrefix:homeDirectory]) { return relativePath; }
    if ([relativePath hasPrefix:[self getAPPBundlePath]]) { return relativePath; }
    return [homeDirectory stringByAppendingPathComponent:relativePath];
}

- (NSDate *)getFileAccessLastDateAtPath:(NSString *)filePath {
    // filePath lenght is zero cause fileSystemRepresentation throws exception
    if (!filePath || filePath.length == 0) { return [NSDate date];}
    struct stat output;
    NSDate *lastAccessDate;
    int ret = -1;
    @try {
        const char *cRepresentation = [filePath fileSystemRepresentation];
        ret = stat(cRepresentation, &output);
    } @catch (NSException *exception) {
        // the file or folder path can't transform or transform failure, will throw exception
        ret = -1; // excption -> failure
    }
    //no error
    if(ret == 0) {
        long accessTimeInterval = output.st_atimespec.tv_sec;
        long changeTimeInterval = output.st_ctimespec.tv_sec;
        long modifyTimeInterval = output.st_mtimespec.tv_sec;

        //accessTime is not accurate after downloading and unzipped the resource bundle，Compare the time of modification(modifyTimeInterval), the time of write(changeTimeInterval) and the time of last access(accessTimeInterval) and take the latest time.
        long validTimeInterval = accessTimeInterval;
        if (validTimeInterval < changeTimeInterval) validTimeInterval = changeTimeInterval;
        if (validTimeInterval < modifyTimeInterval) validTimeInterval = modifyTimeInterval;
        lastAccessDate = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)validTimeInterval];
    } else {
        lastAccessDate = [NSDate date];
    }

    return lastAccessDate;
}

#pragma mark - override
- (long long)folderSpace {
    if (_folderSpace == 0) {
        if (!HMDIsEmptyString(self.currenFolderPath)) {
            BOOL isAbnormal = NO;
            BOOL isOutdated = YES;
            const char *folderPathChar = [self.currenFolderPath cStringUsingEncoding:NSUTF8StringEncoding];
            _folderSpace = [self recursiveCalculateAtPath:folderPathChar isAbnormal:&isAbnormal isOutdated:&isOutdated needCheckIgnorePath:YES];
        }
    }

    return _folderSpace;
}

@end
