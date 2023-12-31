//
//  HMDFolderInfo.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/19.
//

#import "HMDFolderInfo.h"
#import "NSDictionary+HMDSafe.h"
#import "NSArray+HMDSafe.h"
#import "NSString+HDMUtility.h"
#include "pthread_extended.h"
#import "HMDGCD.h"
#import "HMDFolderInfoModel.h"
#import "HMDPathComplianceTool.h"

#define kHMDFolderInfoNormalSearchLevel 2
#define kHMDFolderInfoNormalSearchLevelMax 5
#define kHMDFolderInfoMaxChildInfoCount 100
#define kHMDFolderInfoFileSeperatorStr @"/"

static NSString * const kHMDFolderInfoDataAndDoucmentsContainLibraryPath =  @"Library";
static NSString * const kHMDFolderInfoDataAndDoucmentsContainDocumentsPath =  @"Documents";
static NSString * const kHMDFolderInfoDataAndDoucmentsExceptPath = @"Library/Caches";
static NSString * const kHMDFolderInfoReportDataNextDiskKey = @"next_disk";
static NSString * const kHMDFolderInfoReportDataPathKey = @"path";
static NSString * const kHMDFolderInfoReportDataSizeKey = @"size";
static NSString * const kHMDFolderInfoReportDataSizeRateKey = @"size_rate";
static NSString * const kHMDFolderInfoReportDataReportTypeKey = @"report_type";
static NSString * const kHMDFolderInfoReportDataIsFolderKey = @"is_folder";
static NSString * const kHMDFolderInfoReportDataReportTypeCustom = @"custom";
static NSString * const kHMDFolderInfoReportDataReportTypeNormal = @"normal";

@interface HMDFolderInfo()
/// 自定义 setting 下发的 目录的信息
@property (nonatomic, strong) NSMutableDictionary<NSString *, HMDFolderInfoModel *> *customFolderMap;
@property (nonatomic, strong) HMDFolderInfoModel *rootFolder;
/// 自定义路径的列表
@property (nonatomic, strong) NSMutableDictionary *customConfigDict;
/// 自定义路径兼容正则格式
@property (nonatomic, strong) NSMutableSet *customRegConfigSet;
@property (nonatomic, strong) NSMutableDictionary *documentsAndDataSizeDict;
@property (nonatomic, assign) NSUInteger libraryCacheSize;
@property (nonatomic, strong) dispatch_queue_t operationQueue;
@property (nonatomic, copy) NSDictionary<NSString *, HMDFolderSearchDepthInfo *> *customDepthInfo;

@end

@implementation HMDFolderInfo

#pragma mark --- life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupData];
    }
    return self;
}

- (void)setupData {
    self.customFolderMap = [NSMutableDictionary dictionary];
    self.customConfigDict = [NSMutableDictionary dictionary];
    self.customRegConfigSet = [NSMutableSet set];
    self.documentsAndDataSizeDict = [NSMutableDictionary dictionary];
    self.operationQueue = dispatch_queue_create("com.folder.size.collector.operation", DISPATCH_QUEUE_SERIAL);
    self.rootFolder = [[HMDFolderInfoModel alloc] initWithPath:@"root"];
    self.fileMaxRecursionDepth = kHMDFolderInfoNormalSearchLevel;
}

- (void)setFileMaxRecursionDepth:(NSUInteger)fileMaxRecursionDepth {
    if (fileMaxRecursionDepth < kHMDFolderInfoNormalSearchLevel) {
        _fileMaxRecursionDepth = kHMDFolderInfoNormalSearchLevel;
        return;
    }
    if (fileMaxRecursionDepth > kHMDFolderInfoNormalSearchLevelMax) {
        _fileMaxRecursionDepth = kHMDFolderInfoNormalSearchLevelMax;
        return;
    }
    _fileMaxRecursionDepth = fileMaxRecursionDepth;
}

#pragma mark --- folder and file size info collect
- (void)visitFile:(NSString *)path size:(NSUInteger)size lastAccessDate:(NSDate *)date deepLevel:(NSInteger)deepLevel {
    if (path.length == 0) { return; }
    if (size <= self.collectMinSize) { return; }
    NSString *pathCopy = [path copy];
    NSString *relativePath = [self translateAbsolutePathToRelative:pathCopy];
    BOOL isCustom = [self checkCustomPathWithPath:relativePath size:size isFolder:NO];
    if (isCustom) { return; }
    [self recordFolderInfoWithRelativePath:relativePath size:size deepLevel:deepLevel isFolder:NO];
}

- (void)visitDirectory:(NSString *)path size:(NSUInteger)size deepLevel:(NSUInteger)deepLevel {
    if (path.length == 0) { return; }
    if (size <= self.collectMinSize) { return; }
    NSString *pathCopy = [path copy];
    NSString *relativePath = [self translateAbsolutePathToRelative:pathCopy];
    BOOL isCustom = [self checkCustomPathWithPath:relativePath size:size isFolder:YES];
    if (isCustom) { return; }
    [self recordFolderInfoWithRelativePath:relativePath size:size deepLevel:deepLevel isFolder:YES];
}

- (void)recordFolderInfoWithRelativePath:(NSString *)relativePath
                                  size:(NSUInteger)size
                             deepLevel:(NSUInteger)deepLevel
                              isFolder:(BOOL)isFolder {
    BOOL needRecord = [self needAddToReportFolderInfo:relativePath depthLevel:deepLevel];
    if (!needRecord) { return; } // filter

    NSArray<NSString *> *pathComponents = [relativePath componentsSeparatedByString:@"/"];
    HMDFolderInfoModel *currenFolder = [self infoModelWithPath:relativePath
                                                          size:size
                                                      isFolder:isFolder
                                              isUserCustomPath:NO
                                                         level:deepLevel];
    // find belong folder
    HMDFolderInfoModel *parentFolder = self.rootFolder;
    HMDFolderInfoModel *lastFolder = nil;
    NSString *currentPath = @"";
    for(NSString *component in pathComponents) {
        @autoreleasepool {
            currentPath = currentPath.length > 0 ? [currentPath stringByAppendingPathComponent:component] : component;
            parentFolder = lastFolder ? lastFolder : self.rootFolder;
            lastFolder = [parentFolder.childs hmd_objectForKey:currentPath class:HMDFolderInfoModel.class];
            if (lastFolder == nil) {
                lastFolder = [[HMDFolderInfoModel alloc] initWithPath:currentPath];
                [parentFolder.childs setValue:lastFolder forKey:currentPath];
            }
        }
    }

    parentFolder.includeFolder = parentFolder.includeFolder || isFolder;
    NSMutableDictionary *childsFolders = lastFolder.childs;
    if (childsFolders.count > 0) {
        [currenFolder.childs addEntriesFromDictionary:childsFolders];
    }
    currenFolder.includeFolder = currenFolder.includeFolder || lastFolder.includeFolder;
    if (parentFolder.childs.count <= kHMDFolderInfoMaxChildInfoCount) {
        [parentFolder.childs setValue:currenFolder forKey:currentPath];
    }

    if ([relativePath isEqualToString:kHMDFolderInfoDataAndDoucmentsContainLibraryPath] ||
        [relativePath isEqualToString:kHMDFolderInfoDataAndDoucmentsContainDocumentsPath]) {
        [self.documentsAndDataSizeDict hmd_setObject:@(size) forKey:relativePath];
    }

    if ([relativePath isEqualToString:kHMDFolderInfoDataAndDoucmentsExceptPath]) {
        self.libraryCacheSize = size;
    }
}

- (BOOL)needAddToReportFolderInfo:(NSString *)path depthLevel:(NSUInteger)depthLevel {
    if (depthLevel < 1 ) { return NO;} // root path filter
    if (depthLevel <= self.fileMaxRecursionDepth) { return YES; }
    if (!self.allowCustomLevel) { return NO; }
    if (self.customDepthInfo.count < 1) { return NO; }

    BOOL needAdd = NO;
    NSArray *pathComponents = [path componentsSeparatedByString:kHMDFolderInfoFileSeperatorStr];
    __block NSDictionary *curSearchInfo = self.customDepthInfo;
    __block NSUInteger nearestConfigDepth = 0;
    __block HMDFolderSearchDepthInfo *nearestInfo = nil;
    [pathComponents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        HMDFolderSearchDepthInfo *searchInfo = [curSearchInfo hmd_objectForKey:(NSString *)obj class:[HMDFolderSearchDepthInfo class]];
        if (searchInfo == nil) {
            *stop = YES;
            return;
        }
        nearestConfigDepth = idx;
        nearestInfo = searchInfo;
        curSearchInfo = searchInfo.subFolders;
    }];

    if (nearestConfigDepth == 0 &&
        nearestInfo == nil) {
        return NO;
    }
    NSUInteger nearestFindDepth = nearestInfo == nil ? 0 : nearestInfo.searchDepth.intValue;
    // + 1 because: array subindex begin from 0, but pathComponent first path's depth is 1 in FolderInfo's file depth manager
    nearestConfigDepth = nearestInfo == nil ? 0 : (nearestConfigDepth + 1);
    needAdd =  depthLevel <=(nearestConfigDepth + nearestFindDepth);
    return needAdd;
}

#pragma mark --- config
- (void)customPathWithConfigDict:(NSDictionary *)configDict {
    if ([configDict isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictCopy = [configDict copy];
        dispatch_async(self.operationQueue, ^{
            [self.customConfigDict removeAllObjects];
            [self.customRegConfigSet removeAllObjects];
            [dictCopy enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([key isKindOfClass:[NSString class]]) {
                    NSString *formatPath = [self formatPathWithOriginPath:key];
                    [self.customConfigDict setValue:obj forKey:formatPath];
                    if ([obj isKindOfClass:NSNumber.class] && [obj boolValue]) {
                        NSError *error;
                        NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:formatPath options:0 error:&error];
                        if (reg != nil && error == nil) {
                            [self.customRegConfigSet addObject:reg];
                        }
                    }
                }
            }];
        });
    }
}

- (void)addCustomSearchDepathConfig:(NSDictionary *)depathDict {
    if ([depathDict isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictCopy = [depathDict copy];
        dispatch_async(self.operationQueue, ^{
            self.customDepthInfo = [self resolutionCustomDepthDict:dictCopy];
        });
    }
}

- (NSDictionary *)resolutionCustomDepthDict:(NSDictionary *)oriDict {
    NSMutableDictionary *resolutionRes = [NSMutableDictionary dictionary];
    [oriDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![key isKindOfClass:[NSString class]]) { return; }
        NSString *path = [self formatPathWithOriginPath:key];
        NSArray *pathComponents = [path componentsSeparatedByString:kHMDFolderInfoFileSeperatorStr];
        HMDFolderSearchDepthInfo *lastInfo = nil;
        NSMutableDictionary *currentInfo = resolutionRes;
        for (NSString *subPath in pathComponents) {
            lastInfo = [currentInfo valueForKey:subPath];
            if (!lastInfo) {
                lastInfo = [[HMDFolderSearchDepthInfo alloc] init];
                lastInfo.path = subPath;
                lastInfo.searchDepth = @(0);
                [currentInfo hmd_setObject:lastInfo forKey:subPath];
            }
            currentInfo = lastInfo.subFolders;
        }
        // avoid obj type invalid
        lastInfo.searchDepth = [NSNumber numberWithInt:[oriDict hmd_intForKey:key]];
    }];

    return [resolutionRes copy];
}

#pragma mark --- product report data
- (NSArray *)reportDiskFolderInfoWithAppFolderSize:(double)appFolderSize {
    return [self reportDiskFolderInfoWithAppFolderSize:appFolderSize compliancePaths:nil];
}

- (NSArray *)reportDiskFolderInfoWithAppFolderSize:(double)appFolderSize compliancePaths:(NSArray<NSString*>*)compliancePaths {
    NSMutableArray *array = [NSMutableArray array];
    NSArray *normalReportArray = [self folderInfosDictWithAppFolderSize:appFolderSize folderInfo:self.rootFolder.childs compliancePaths:compliancePaths matchedPrefix:nil];
    if (normalReportArray && normalReportArray.count > 0) {
        [array addObjectsFromArray:normalReportArray];
    }
    NSArray *customReportArray = [self folderInfosDictWithAppFolderSize:appFolderSize folderInfo:self.customFolderMap compliancePaths:compliancePaths matchedPrefix:nil];
    if (customReportArray && customReportArray.count > 0) {
        [array addObjectsFromArray:customReportArray];
    }

    return [array copy];
}

- (NSArray *)folderInfosDictWithAppFolderSize:(double)appFolderSize folderInfo:(NSDictionary *)folderMap compliancePaths:(NSArray<NSString*>*)compliancePaths matchedPrefix:(NSString*)matchedPrefix{
    NSMutableArray *normalFolders = [NSMutableArray array];
    for (HMDFolderInfoModel *folderInfo in folderMap.allValues) {
        @autoreleasepool {
            if (![folderInfo isKindOfClass:[HMDFolderInfoModel class]]) { continue;}
            NSMutableDictionary *reportDict = [NSMutableDictionary dictionary];
            // 路径
            NSString *path = folderInfo.path;
            NSString *matchedPrefixCur = matchedPrefix;
            if (compliancePaths.count > 0) {
                // 脱敏逻辑，如果父级目录命中脱敏规则，则子目录不做额外判断，直接进行脱敏
                if (matchedPrefix) {
                    path = [HMDPathComplianceTool complianceReleativePath:path prefixPath:matchedPrefix];
                }else {
                // 否则，需要对子目录进行判断是否命中脱敏规则
                    BOOL prefixMatched;
                    NSString *tmp = [HMDPathComplianceTool compareReleativePath:path compliancePaths:compliancePaths isMatch:&prefixMatched];
                    if (prefixMatched) {
                        matchedPrefixCur = tmp;
                    }
                }
            }
            
            [reportDict setValue:path forKey:kHMDFolderInfoReportDataPathKey];
            // 磁盘占用大小
            [reportDict setValue:@(folderInfo.size) forKey:kHMDFolderInfoReportDataSizeKey];
            // 磁盘占用比例
            NSUInteger folderSize = folderInfo.size;
            float rate = 0;
            if (appFolderSize > 0) {
                rate = (float)(folderSize / appFolderSize);
            }
            [reportDict setValue:@(rate) forKey:kHMDFolderInfoReportDataSizeRateKey];
            // 上报类型
            [reportDict setValue:folderInfo.reportType?:kHMDFolderInfoReportDataReportTypeCustom forKey:kHMDFolderInfoReportDataReportTypeKey];
            // 文件类型
            [reportDict setValue:@(folderInfo.isFolder) forKey:kHMDFolderInfoReportDataIsFolderKey];
            // 下一级目录
            NSDictionary *childFiles = folderInfo.childs;
            BOOL needReportChildFiles = folderInfo.level < self.fileMaxRecursionDepth || folderInfo.includeFolder;
            if (childFiles && childFiles.count > 0 && needReportChildFiles) {
                NSArray *nextReportDict = [self folderInfosDictWithAppFolderSize:appFolderSize folderInfo:childFiles compliancePaths:compliancePaths matchedPrefix:matchedPrefixCur];
                [reportDict setValue:nextReportDict forKey:kHMDFolderInfoReportDataNextDiskKey];
            }
            [normalFolders hmd_addObject:reportDict];
        }
    }

    return normalFolders;
}

- (NSArray *)folderInfosDictWithAppFolderSize:(double)appFolderSize folderInfo:(NSDictionary *)folderMap {
    return [self folderInfosDictWithAppFolderSize:appFolderSize folderInfo:folderMap compliancePaths:nil matchedPrefix:nil];
}

- (void)clearData {
    [self.rootFolder.childs removeAllObjects];
    [self.customFolderMap removeAllObjects];
}

#pragma mark --- Document and data size ---
- (NSInteger)sizeOfDocumentsAndData {
    NSUInteger totalSize = 0;
    for (NSNumber *fileSize in self.documentsAndDataSizeDict.allValues) {
        totalSize += [fileSize unsignedIntegerValue];
    }
    totalSize = totalSize - self.libraryCacheSize;
    return totalSize;
}

#pragma mark --- path string deal utilities
- (NSString *)translateAbsolutePathToRelative:(NSString *)absolutePath {
    if(absolutePath == nil) return nil;
    NSString * basePath = [self getAPPHomeDirectory];
    if ([absolutePath hasPrefix:basePath]) {
        NSString *relativePath = nil;
        if (absolutePath.length > basePath.length) {
            relativePath = [absolutePath substringFromIndex:basePath.length];
        } else {
            relativePath = @"";
        }
        NSString *formatPath = [self formatPathWithOriginPath:relativePath];
        return formatPath;
    }
    return absolutePath;
}

/// 格式化路径 防止 前面多一个 / 或者 后面多一个 / 造成 路径的不统一
- (NSString *)formatPathWithOriginPath:(NSString *)path {
    if ([path hasPrefix:kHMDFolderInfoFileSeperatorStr]) {
        path = [path stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
    }
    if ([path hasSuffix:kHMDFolderInfoFileSeperatorStr]) {
        path = [path stringByReplacingCharactersInRange:NSMakeRange(path.length - 1, 1) withString:@""];
    }
    return path;
}

- (BOOL)checkCustomPathWithPath:(NSString *)relativePath
                           size:(NSUInteger)size
                       isFolder:(BOOL)isFolder {
    __block BOOL isCustom = [self.customConfigDict hmd_boolForKey:relativePath];
    
    if (!isCustom) {
        NSRange range = NSMakeRange(0, relativePath.length);
        [self.customRegConfigSet enumerateObjectsUsingBlock:^(NSRegularExpression*  _Nonnull obj, BOOL * _Nonnull stop) {
            NSTextCheckingResult *result = [obj firstMatchInString:relativePath options:0 range:range];
            if (result && NSEqualRanges(range, result.range)) {
                isCustom = YES;
                *stop = YES;
            }
        }];
    }
    
    if (isCustom) {
        HMDFolderInfoModel *folderInfo = [self infoModelWithPath:relativePath
                                                            size:size
                                                        isFolder:isFolder
                                                isUserCustomPath:YES
                                                           level:0];
        [self.customFolderMap setValue:folderInfo forKey:relativePath];
    }
    return isCustom;
}

#pragma mark -- model and dict transform
- (HMDFolderInfoModel *)infoModelWithPath:(NSString *)path
                                     size:(NSUInteger)size
                                 isFolder:(BOOL)isFolder
                         isUserCustomPath:(BOOL)isCustomPath
                                    level:(NSUInteger)level {
    HMDFolderInfoModel *infoModel = [[HMDFolderInfoModel alloc] init];
    infoModel.path = path;
    infoModel.size = size;
    infoModel.isFolder = isFolder;
    infoModel.reportType = isCustomPath ? kHMDFolderInfoReportDataReportTypeCustom : kHMDFolderInfoReportDataReportTypeNormal;
    infoModel.level = level;

    return infoModel;
}

- (NSString *)getAPPHomeDirectory {
    static NSString *homeDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        homeDirectory = NSHomeDirectory();
    });
    return homeDirectory;
}

@end
