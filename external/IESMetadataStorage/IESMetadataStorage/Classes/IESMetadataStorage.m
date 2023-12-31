//
//  IESMetadataStorage.m
//  IESMetadataStorage_Example
//
//  Created by 陈煜钏 on 2021/1/26.
//

#import "IESMetadataStorage.h"

#import <pthread/pthread.h>
#import <objc/runtime.h>

#import "IESMetadataStorageDefines+Private.h"
#import "IESMetadataStorageInfo.h"
#import "IESMetadataMappedFile.h"
#import "IESMetadataUtils.h"
#import "IESMetadataLog.h"
#import "IESMetadataIndexesMap.h"
#import "NSData+IESMetadata.h"
#import "NSError+IESMetadata.h"

static int IESMetadataUnitLength = 1024;
static int IESMetadataContentLocation = 64;

static pthread_mutex_t IESMetadataStorageLock = PTHREAD_MUTEX_INITIALIZER;

@interface IESMetadataStorageInfo ()
@property (nonatomic, assign) int version;
@property (nonatomic, assign) BOOL checkDuplicatedMetadatas;
@end

@interface IESMetadataStorage ()

@property (nonatomic, strong) IESMetadataStorageConfiguration *configuration;

@property (nonatomic, strong) IESMetadataStorageInfo *storageInfo;

@property (nonatomic, strong) IESMetadataMappedFile *mappedFile;

@property (nonatomic, strong) IESMetadataIndexesMap *indexesMap;

@end

@implementation IESMetadataStorage

#pragma mark - Public

+ (instancetype)storageWithConfiguration:(IESMetadataStorageConfiguration *)configuration
{
    if (![configuration isValid]) {
        return nil;
    }
    IESMetadataLogInfo("create metadata storage at filepath : %@, capacity : %zd",
                       configuration.filePath, configuration.metadataCapacity);
    
    IESMetadataStorage *storage = [[IESMetadataStorage alloc] init];
    storage.configuration = configuration;
    return storage;
}

- (NSArray<IESMetadataType *> *)metadatasArrayWithTransformBlock:(IESMetadataTransformBlock)transformBlock
{
    return [self metadatasArrayWithTransformBlock:transformBlock
                                     compareBlock:nil];
}

- (NSArray<IESMetadataType *> *)metadatasArrayWithTransformBlock:(IESMetadataTransformBlock)transformBlock
                                                    compareBlock:(IESMetadataCompareBlock _Nullable)compareBlock
{
    NSAssert(transformBlock, @"Transform block should not be nil.");
    if (!transformBlock) {
        return @[];
    }
    
    MD_MUTEX_LOCK(IESMetadataStorageLock);
    
    [self setupStorageIfNeeded];
    
    int count = self.mappedFile.fileSize / IESMetadataUnitLength;
    if (count < 1) {
        IESMetadataLogError("read metadata failed, file size : %d [%@]", self.mappedFile.fileSize, self.configuration.filePath);
        return @[];
    }
    BOOL checkDuplicatedMetadatas = self.storageInfo.checkDuplicatedMetadatas;
    if (checkDuplicatedMetadatas) {
        self.storageInfo.checkDuplicatedMetadatas = NO;
        [self saveStorageInfoToLocal];
    }
    
    __block int duplicatedCount = 0;
    NSMutableDictionary<NSNumber *, IESMetadataType *> *metadatasDictionary = [NSMutableDictionary dictionaryWithCapacity:count - 1];
    dispatch_semaphore_t metadatasLock = dispatch_semaphore_create(1);
    dispatch_apply(count, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^(size_t idx) {
        int index = (int)idx;
        if (index == 0) {
            // 第一个是文件元信息
            return;
        }
        
        int currentLocation = index * IESMetadataUnitLength;
        bool isValid = [self.mappedFile boolValueAtLocation:currentLocation];
        if (!isValid) {
            return;
        }
        
        NSData *contentData = [self metadataContentDataAtIndex:index offset:sizeof(bool)];
        if (contentData.length == 0) {
            // 数据校验出错，标记废弃
            [self.mappedFile writeBool:false location:currentLocation];
            return;
        }
        
        NSObject<IESMetadataProtocol> *metadata = transformBlock(contentData);
        NSAssert(metadata, @"Metadata should not be nil");
        if (!metadata) {
            return;
        }
        
        dispatch_semaphore_wait(metadatasLock, DISPATCH_TIME_FOREVER);
        // 一定要把重复检测逻辑放在这个锁里，保证不同 metadata 之间检测逻辑不是并发的
        int duplicatedIndex = -1;
        if (checkDuplicatedMetadatas) {
            duplicatedIndex = [_indexesMap indexForMetadata:metadata];
        }
        BOOL updateIndex = YES;
        if (duplicatedIndex != -1) { // 发现重复
            duplicatedCount++;
            
            BOOL override = NO;
            if (compareBlock) {
                IESMetadataType *previousOne = metadatasDictionary[@(duplicatedIndex)];
                override = compareBlock(previousOne, metadata);
            }
            if (!override) {
                // 用之前的，当前的位置标记废弃
                updateIndex = NO;
                [self.mappedFile writeBool:false location:currentLocation];
            } else {
                // 用新的，旧的位置标记废弃
                metadatasDictionary[@(duplicatedIndex)] = nil;
                [self.mappedFile writeBool:false location:duplicatedIndex * IESMetadataUnitLength];
            }
        }
        if (updateIndex) {
            metadatasDictionary[@(index)] = metadata;
            [_indexesMap setIndex:index forMetadata:metadata];
        }
        dispatch_semaphore_signal(metadatasLock);
    });
    // 去重后的元信息
    NSArray<IESMetadataType *> *result = metadatasDictionary.allValues;
    int capacity = self.configuration.metadataCapacity;
    if (result.count < capacity && duplicatedCount + result.count > capacity) {
        // 去重前的数量大于 capacity 则重置文件，减小文件大小
        [self resetFileWithMetadatasArray:result];
    }
    return result;
}

- (int)writeMetadata:(IESMetadataType *)metadata error:(NSError *__autoreleasing  _Nullable * _Nullable)error
{
    NSAssert([metadata conformsToProtocol:@protocol(IESMetadataProtocol)], @"Metadata should conforms to IESMetadataProtocol.");
    
    MD_MUTEX_LOCK(IESMetadataStorageLock);
    
    [self setupStorageIfNeeded];
    
    int lastIndex = [_indexesMap indexForMetadata:metadata];
    int count = self.mappedFile.fileSize / IESMetadataUnitLength;
    int indexToWrite = -1;
    if ((lastIndex > 0) && (lastIndex < count)) {
        // 元信息已存在，直接覆写
        indexToWrite = lastIndex;
    } else {
        // 查找可写入位置
        for (int index = 1; index < count; index++) {
            int currentLocation = index * IESMetadataUnitLength;
            
            bool isValid = [self.mappedFile boolValueAtLocation:currentLocation];
            if (!isValid) {
                indexToWrite = index;
                break;
            }
        }
    }
    if (indexToWrite == -1) {
        // 没有找到写入位置，扩大文件内容
        if ([self.mappedFile extendFile]) {
            indexToWrite = count;
        } else {
            if (error) {
                *error = [NSError iesmetadata_errorWithCode:IESMetadataErrorCodeWrite
                                                description:@"Extend file failed"];
            }
            return -1;
        }
    }
    
    NSError *writeError = nil;
    if ([self writeMetadata:metadata index:indexToWrite error:&writeError]) {
        return indexToWrite;
    }
    if (error) {
        *error = writeError;
    }
    return -1;
}

- (void)deleteMetadata:(IESMetadataType *)metadata
{
    MD_MUTEX_LOCK(IESMetadataStorageLock);
    
    [self setupStorageIfNeeded];
    
    int lastIndex = [_indexesMap indexForMetadata:metadata];
    int count = self.mappedFile.fileSize / IESMetadataUnitLength;
    if ((lastIndex > 0) && (lastIndex < count)) {
        int metadataLocation = lastIndex * IESMetadataUnitLength;
        [self.mappedFile writeBool:false location:metadataLocation];
    } else {
        IESMetadataLogWarning("metadata not found at index : %d, count : %d, path : %@", lastIndex, count, self.configuration.filePath);
    }
    
    [_indexesMap setIndex:-1 forMetadata:metadata];
}

- (void)deleteAllMetadata
{
    MD_MUTEX_LOCK(IESMetadataStorageLock);
    
    [self setupStorageIfNeeded];
    
    int count = self.mappedFile.fileSize / IESMetadataUnitLength;
    for (int index = 1; index < count; index++) {
        int currentLocation = index * IESMetadataUnitLength;
        [self.mappedFile writeBool:false location:currentLocation];
    }
    
    [_indexesMap clearAllIndexes];
}

- (void)setNeedCheckDuplicatedMetadatas
{
    MD_MUTEX_LOCK(IESMetadataStorageLock);
    
    [self setupStorageIfNeeded];
    
    self.storageInfo.checkDuplicatedMetadatas = YES;
    [self saveStorageInfoToLocal];
}

- (int)indexForMetadata:(IESMetadataType *)metadata
{
    return [_indexesMap indexForMetadata:metadata];
}

#pragma mark - Private

- (void)setupStorageIfNeeded
{
    if ([objc_getAssociatedObject(self, _cmd) boolValue]) {
        return;
    }
    objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    int mapLength = self.configuration.metadataCapacity * IESMetadataUnitLength;
    self.mappedFile = [IESMetadataMappedFile mappedFileWithPath:self.configuration.filePath
                                                      mapLength:mapLength];
    
    self.indexesMap = [[IESMetadataIndexesMap alloc] init];
    
    self.storageInfo = [self storageInfoFromLocal];
    if (!self.storageInfo) {
        self.storageInfo = [IESMetadataStorageInfo defaultInfo];
        [self saveStorageInfoToLocal];
        
        IESMetadataLogInfo("save storage info to local, version : %zd", self.storageInfo.version);
        return;
    }
    
    int version = self.storageInfo.version;
    IESMetadataLogInfo("load storage info from local, version : %zd", version);
    if (version != IESMetadataStorageInfoVersion) {
        self.storageInfo.version = IESMetadataStorageInfoVersion;
        [self saveStorageInfoToLocal];
        
        IESMetadataLogInfo("local storage info version : %zd current version : %zd", version, IESMetadataStorageInfoVersion);
    }
}

- (void)saveStorageInfoToLocal
{
    NSData *binaryData = [self.storageInfo binaryData];
    int currentLocation = 0;
    
    // 写入 magicHeader
    int magicHeaderLength = (int)strlen(IESMetadataStorageMagicHeader);
    [self.mappedFile writeChars:IESMetadataStorageMagicHeader location:currentLocation];
    currentLocation += magicHeaderLength;
    
    [self writeMetadataBinaryData:binaryData
                            index:0
                           offset:currentLocation
                            error:NULL];
}

- (IESMetadataStorageInfo *)storageInfoFromLocal
{
    int currentLocation = 0;
    
    // 校验 magicHeader
    int magicHeaderLength = (int)strlen(IESMetadataStorageMagicHeader);
    const char *magicHeader = [self.mappedFile charsAtLocation:currentLocation length:magicHeaderLength] ? : "";
    if (strcmp(magicHeader, IESMetadataStorageMagicHeader) != 0) {
        return nil;
    }
    currentLocation += magicHeaderLength;
    
    NSData *storageData = [self metadataContentDataAtIndex:0 offset:currentLocation];
    return (storageData.length > 0) ? [IESMetadataStorageInfo infoWithData:storageData] : nil;
}

- (BOOL)writeMetadata:(IESMetadataType *)metadata index:(int)index error:(NSError *__autoreleasing  _Nullable * _Nullable)error
{
    NSError *writeError = nil;
    NSData *binaryData = [metadata binaryData];
    bool isValid = true;
    if ([self writeMetadataBinaryData:binaryData index:index offset:sizeof(bool) error:&writeError]) {
        [_indexesMap setIndex:index forMetadata:metadata];
        
        int metadataLocation = index * IESMetadataUnitLength;
        [self.mappedFile writeBool:isValid location:metadataLocation];
        return YES;
    }
    
    if (error) {
        *error = writeError;
    }
    return NO;
}

- (BOOL)writeMetadataBinaryData:(NSData *)data index:(int)index offset:(int)offset error:(NSError **)error
{
    if (data.length == 0) {
        NSString *message = @"Metadata binary data is empty.";
        NSAssert(NO, message);
        if (error) {
            *error = [NSError iesmetadata_errorWithCode:IESMetadataErrorCodeWrite
                                            description:message];
        }
        return NO;
    }
    const int maxContentLength = (IESMetadataUnitLength - IESMetadataContentLocation);
    if (data.length > maxContentLength) {
        NSString *message = [NSString stringWithFormat:@"Metadata binary data length must be less than %d", (maxContentLength + 1)];
        NSAssert(NO, @"Metadata binary data length must be less than %d", (maxContentLength + 1));
        if (error) {
            *error = [NSError iesmetadata_errorWithCode:IESMetadataErrorCodeWrite
                                            description:message];
        }
        return NO;
    }
    
    int metadataLocation = index * IESMetadataUnitLength;
    int currentLocation = metadataLocation + offset;
    // 写入内容长度
    int contentLength = (int)data.length;
    [self.mappedFile writeIntValue:contentLength location:currentLocation];
    currentLocation += sizeof(int);
    
    // 写入 crc32
    uint32_t crc32 = [data iesmetadata_crc32];
    [self.mappedFile writeCrc32:crc32 location:currentLocation];
    currentLocation += sizeof(uint32_t);
    
    // 写入内容
    int contentLocation = metadataLocation + IESMetadataContentLocation;
    if (contentLocation < currentLocation) {
        NSString *message = @"Metadata content location is invalid.";
        NSAssert(NO, message);
        if (error) {
            *error = [NSError iesmetadata_errorWithCode:IESMetadataErrorCodeWrite
                                            description:message];
        }
        return NO;
    }
    [self.mappedFile writeData:data location:contentLocation];
    return YES;
}

- (NSData *)metadataContentDataAtIndex:(int)index offset:(int)offset
{
    int metadataLocation = index * IESMetadataUnitLength;
    int currentLocation = metadataLocation + offset;
    // 读取内容长度
    int contentLength = [self.mappedFile intValueAtLocation:currentLocation];
    if (contentLength < 0) {
        IESMetadataLogError("metadata content length is negative");
        return nil;
    }
    // 最大内容长度
    const int maxContentLength = (IESMetadataUnitLength - IESMetadataContentLocation);
    if (contentLength > maxContentLength) {
        IESMetadataLogError("metadata content length out of limit : %zd", contentLength);
        return nil;
    }
    
    currentLocation += sizeof(int);
    // 读取 crc32
    uint32_t crc32 = [self.mappedFile crc32AtLocation:currentLocation];
    currentLocation += sizeof(uint32_t);
    // 读取内容
    int contentLocation = metadataLocation + IESMetadataContentLocation;
    NSData *contentData = [self.mappedFile dataAtLocation:contentLocation length:contentLength];
    // 校验
    if ([contentData iesmetadata_checkCrc32:crc32]) {
        return contentData;
    }
    IESMetadataLogError("metadata check crc32 failed : crc32 : %u, contentLength : %zd", crc32, contentData.length);
    return nil;
}

- (void)resetFileWithMetadatasArray:(NSArray<IESMetadataType *> *)metadatasArray
{
    if (![self.mappedFile resetToNewFile]) {
        return;
    }
    
    [self saveStorageInfoToLocal];
    
    int availableCount = self.mappedFile.fileSize / IESMetadataUnitLength;
    NSUInteger metadataCount = metadatasArray.count;
    for (int i = 0; i < metadataCount; i++) {
        int indexToWrite = i + 1; // 第一个元信息是 storageInfo
        if (indexToWrite >= availableCount) {
            if (![self.mappedFile extendFile]) {
                // 扩展文件失败，不再写入
                break;
            }
            availableCount = self.mappedFile.fileSize / IESMetadataUnitLength;
        }
        IESMetadataType *metadata = metadatasArray[i];
        [self writeMetadata:metadata index:indexToWrite error:NULL];
    }
}

#pragma mark - Accessor

- (int)version
{
    return self.storageInfo.version;
}

@end
