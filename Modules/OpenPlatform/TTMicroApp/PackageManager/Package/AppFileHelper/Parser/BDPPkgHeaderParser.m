//
//  BDPPkgHeaderParser.m
//  Timor
//
//  Created by 傅翔 on 2019/1/22.
//

#import "BDPPkgHeaderParser.h"
#import "BDPPkgHeaderInfo.h"
#import "BDPAppLoadDefineHeader.h"
#import <TTMicroApp/TTMicroApp-Swift.h>

#define VERSION 1
#define FIELD_BYTES 4 // 字段默认字节数

/** 当前解析目标, 顺序逐个解析 */
typedef NS_ENUM(NSUInteger, ParseTarget) {
    /** 文件标识 */
    ParseTargetID,
    /** 文件版本号 */
    ParseTargetVersion,
    /** 文件拓展信息长度 */
    ParseTargetExtLength,
    /** 文件拓展信息 */
    ParseTargetExtInfo,
    /** 包含文件数量 */
    ParseTargetFileCount,
    /** 文件索引信息(该目标还分多个类型, 具体看ParseFileIndexInfoType枚举值) */
    ParseTargetFileIndexInfo
};

/** 当前解析文件索引信息类型 */
typedef NS_ENUM(NSUInteger, ParseFileIndexInfoType) {
    /** 文件名长度 */
    ParseFileIndexInfoTypeNameSize,
    /** 文件名 */
    ParseFileIndexInfoTypeName,
    /** 文件偏移量 */
    ParseFileIndexInfoTypeOffset,
    /** 文件大小 */
    ParseFileIndexInfoTypeSize
};

@interface BDPPkgHeaderParser ()

/** 当前解析目标(状态) */
@property (nonatomic, assign) ParseTarget target;
/** 文件索引信息的具体类型 */
@property (nonatomic, assign) ParseFileIndexInfoType infoType;
@property (nonatomic, assign) BOOL canContinue;

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) BDPPkgHeaderInfo *fileInfo;
/** 当前解析中的FileIndex */
@property (nonatomic, strong) BDPPkgFileIndexInfo *curFileIndexModel;
@property (nonatomic, strong) NSMutableArray<BDPPkgFileIndexInfo *> *fileIndexes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDPPkgFileIndexInfo *> *fileIndexesDic;
@property (nonatomic, strong) dispatch_semaphore_t dataSemaphore;
@property (nonatomic, assign) BOOL enableHeaderParserProtection;

/** 文件拓展字节数 */
@property (nonatomic, assign) uint32_t fileExtSize;
/** 文件索引数量(即包内文件数量) */
@property (nonatomic, assign) uint32_t fileCount;
/** 当前解析文件名长度 */
@property (nonatomic, assign) uint32_t fileNameSize;
/** 解析位置, 偏移量 */
@property (nonatomic, assign) uint64_t offset;

@property (nonatomic, strong) NSDate *beginDate;

@end

@interface NSMutableData(ThreadProtection)

@end
@implementation NSMutableData(ThreadProtection)

- (void)getBytes:(void *)buffer length:(NSUInteger)length withSemaphore:(dispatch_semaphore_t __nullable) semaphore {
    if(semaphore!=nil){
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    [self getBytes:buffer length:length];
    if(semaphore!=nil){
        dispatch_semaphore_signal(semaphore);
    }
}

- (void)getBytes:(void *)buffer range:(NSRange)range withSemaphore:(dispatch_semaphore_t __nullable) semaphore {
    if(semaphore!=nil){
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    [self getBytes:buffer range:range];
    if(semaphore!=nil){
        dispatch_semaphore_signal(semaphore);
    }
}

-(void)appendData:(NSData *)data withSemaphore:(dispatch_semaphore_t __nullable) semaphore {
    if(semaphore!=nil){
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    [self appendData:data];
    if(semaphore!=nil){
        dispatch_semaphore_signal(semaphore);
    }
}

@end

@implementation BDPPkgHeaderParser

-(instancetype)initWithProtection:(BOOL) enable {
    self = [super init];
    if(self){
        self.enableHeaderParserProtection = enable;
    }
    return self;
}

- (void)appendData:(NSData *)data {
    if (!self.completionBlk) {
        return;
    }
    if (!self.beginDate) {
        self.beginDate = [NSDate date]; // 解析头的起点时刻
    }
    [self.data appendData:data  withSemaphore:self.dataSemaphore];
    self.canContinue = YES;
    [self tryToParse];
}

- (void)emptyData {
    self.fileInfo = nil;
    self.beginDate = nil;
    self.data = nil;
}

- (void)stopParseWithException:(NSException *)exception {
    if (exception) {
        self.canContinue = NO;
        [self emptyData];
        if (self.completionBlk) {
            self.completionBlk(nil, BDP_APP_LOAD_ERROR_TYPE_N(GDMonitorCodeAppLoad.pkg_mask_verified_failed, exception.reason ?: @"parse failed", BDP_APP_LOAD_TYPE_PKG, nil));
        }
    }
}

#pragma mark - Parse
- (void)tryToParse {
    while (self.canContinue) {
        switch (self.target) {
            case ParseTargetID:
                [self parseFileID];
                break;
            case ParseTargetVersion:
                [self parseFileVersion];
                break;
            case ParseTargetExtLength:
                [self parseFileExtLength];
                break;
            case ParseTargetExtInfo:
                [self parseExtInfo];
                break;
            case ParseTargetFileCount:
                [self parseFileCount];
                break;
            case ParseTargetFileIndexInfo:
                [self parseFileIndexInfo];
                break;
            default:
                break;
        }
    }
}

- (void)tryToParseNextTargetWithSize:(uint32_t)size {
    self.offset += size; // 解析偏移量更新
    self.target++; // 切换下个target
}

- (void)parseFileID {
    if (self.target == ParseTargetID && self.data.length >= FIELD_BYTES) {
        uint8_t bytes[4];
        @try {
            [self.data getBytes:&bytes length:FIELD_BYTES withSemaphore:self.dataSemaphore];
        } @catch (NSException *exception) {
            [self stopParseWithException:exception];
        }
        if (!self.data.length) {
            return;
        }
        if (bytes[0] == 'T' && bytes[1] == 'P' && bytes[2] == 'K' && bytes[3] == 'G') {
            // 校验通过, 初始化描述文件
            self.fileInfo = [[BDPPkgHeaderInfo alloc] init];
            [self tryToParseNextTargetWithSize:FIELD_BYTES];
        } else {
            self.canContinue = NO;
            if (self.completionBlk) {
                NSString *additionInfo = [[NSString alloc] initWithData:self.data
                                                           encoding:NSUTF8StringEncoding];
                self.completionBlk(nil, BDP_APP_LOAD_ERROR_TYPE_N(GDMonitorCodeAppLoad.pkg_mask_verified_failed, additionInfo ?: @"Header Mask invalid.", BDP_APP_LOAD_TYPE_PKG, nil));
            }
        }
    } else {
        self.canContinue = NO;
    }
}

- (void)parseFileVersion {
    if (self.target == ParseTargetVersion && self.data.length >= (self.offset + FIELD_BYTES)) {
        uint32_t version = 0;
        @try {
            [self.data getBytes:&version range:NSMakeRange(self.offset, FIELD_BYTES) withSemaphore:self.dataSemaphore];
        } @catch (NSException *exception) {
            [self stopParseWithException:exception];
        }
        if (!self.data.length) {
            return;
        }
        self.fileInfo.version = version;
        
        if (self.versionValidateBlk && !self.versionValidateBlk(version)) {
            [self emptyData];
            self.canContinue = NO;
            return; // 版本校验不过, 清空, 退出
        }
        
        [self tryToParseNextTargetWithSize:FIELD_BYTES];
    } else {
        self.canContinue = NO;
    }
}

- (void)parseFileExtLength {
    if (self.target == ParseTargetExtLength && self.data.length >= (self.offset + FIELD_BYTES)) {
        uint32_t size = 0;
        @try {
            [self.data getBytes:&size range:NSMakeRange(self.offset, FIELD_BYTES)  withSemaphore:self.dataSemaphore];
        } @catch (NSException *exception) {
            [self stopParseWithException:exception];
        }
        if (!self.data.length) {
            return;
        }
        self.fileExtSize = size;
        
        [self tryToParseNextTargetWithSize:FIELD_BYTES];
    } else {
        self.canContinue = NO;
    }
}

- (void)parseExtInfo {
    if (self.target == ParseTargetExtInfo && self.data.length >= (self.offset + self.fileExtSize)) {
        if (self.fileExtSize > 0) {
            self.fileInfo.extInfo = [self.data subdataWithRange:NSMakeRange(self.offset, self.fileExtSize)];
        }
        [self tryToParseNextTargetWithSize:self.fileExtSize];
    } else {
        self.canContinue = NO;
    }
}

- (void)parseFileCount {
    if (self.target == ParseTargetFileCount && self.data.length >= (self.offset + FIELD_BYTES)) {
        uint32_t fileCount = 0;
        @try {
            [self.data getBytes:&fileCount range:NSMakeRange(self.offset, FIELD_BYTES)  withSemaphore:self.dataSemaphore];
        } @catch (NSException *exception) {
            [self stopParseWithException:exception];
        }
        if (!self.data.length) {
            return;
        }
        
        self.fileCount = fileCount;
        [self tryToParseNextTargetWithSize:FIELD_BYTES];
    } else {
        self.canContinue = NO;
    }
}

- (void)parseFileIndexInfo {
    if (self.target == ParseTargetFileIndexInfo) {
        while (self.canContinue) {
            switch (self.infoType) {
                case ParseFileIndexInfoTypeNameSize:
                    [self parseFileIndexInfoNameSize];
                    break;
                case ParseFileIndexInfoTypeName:
                    if ([OPSDKFeatureGating fixPkgHeaderParseFileNameCrash]) {
                        [self parseFileIndexInfoNameV2];
                    } else {
                        [self parseFileIndexInfoName];
                    }
                    break;
                case ParseFileIndexInfoTypeOffset:
                    [self parseFileIndexInfoOffset];
                    break;
                case ParseFileIndexInfoTypeSize:
                    [self parseFileIndexInfoSize];
                    break;
                default:
                    break;
            }
        }
    } else {
        self.canContinue = NO;
    }
}

- (void)parseNextFileInfoTypeWithSize:(uint32_t)size {
    self.infoType = (self.infoType + 1) % 4;
    self.offset += size;
}

- (void)parseFileIndexInfoNameSize {
    if (self.infoType == ParseFileIndexInfoTypeNameSize && self.data.length >= self.offset + FIELD_BYTES) {
        // namesize是每个文件索引的开头, 创建新的模型记录
        self.curFileIndexModel = [[BDPPkgFileIndexInfo alloc] init];
        
        uint32_t nameSize = 0;
        @try {
            [self.data getBytes:&nameSize range:NSMakeRange(self.offset, FIELD_BYTES)  withSemaphore:self.dataSemaphore];
        } @catch (NSException *exception) {
            [self stopParseWithException:exception];
        }
        if (!self.data.length) {
            return;
        }
        
        self.fileNameSize = nameSize;
        
        [self parseNextFileInfoTypeWithSize:FIELD_BYTES];
    } else {
        self.canContinue = NO;
    }
}

// 解析文件名 Note: 在堆中申请临时空间来存储数据然后解析;原先方法是在将数据保存在栈中,存在栈溢出问题
- (void)parseFileIndexInfoNameV2 {
    if (self.infoType == ParseFileIndexInfoTypeName && self.data.length >= self.offset + self.fileNameSize) {
        if (self.fileNameSize) {
            @try {
                // 此处self.fileNameSize大小不固定, 可能会大到栈溢出, 故改成堆上开辟空间
                size_t tmpSize = (self.fileNameSize + 1) * sizeof(uint8_t);
                uint8_t *bytes = malloc(tmpSize);
                memset(bytes, 0, tmpSize);
                [self.data getBytes:bytes range:NSMakeRange(self.offset, self.fileNameSize)  withSemaphore:self.dataSemaphore];
                
                self.curFileIndexModel.filePath = [[NSString alloc] initWithBytes:bytes length:self.fileNameSize encoding:NSUTF8StringEncoding];
                if (bytes) {
                    free(bytes);
                }
            } @catch (NSException *exception) {
                [self stopParseWithException:exception];
            }
            if (!self.data.length) {
                return;
            }
        }
        [self parseNextFileInfoTypeWithSize:self.fileNameSize];
    } else {
        self.canContinue = NO;
    }
}

- (void)parseFileIndexInfoName {
    if (self.infoType == ParseFileIndexInfoTypeName && self.data.length >= self.offset + self.fileNameSize) {
        if (self.fileNameSize) {
            uint8_t bytes[self.fileNameSize];
            @try {
                [self.data getBytes:&bytes range:NSMakeRange(self.offset, self.fileNameSize)  withSemaphore:self.dataSemaphore];
            } @catch (NSException *exception) {
                [self stopParseWithException:exception];
            }
            if (!self.data.length) {
                return;
            }
            self.curFileIndexModel.filePath = [[NSString alloc] initWithBytes:bytes length:self.fileNameSize encoding:NSUTF8StringEncoding];
        }
        [self parseNextFileInfoTypeWithSize:self.fileNameSize];
    } else {
        self.canContinue = NO;
    }
}

- (void)parseFileIndexInfoOffset {
    if (self.infoType == ParseFileIndexInfoTypeOffset && self.data.length >= self.offset + FIELD_BYTES) {
        uint32_t offset = 0;
        @try {
            [self.data getBytes:&offset range:NSMakeRange(self.offset, FIELD_BYTES)  withSemaphore:self.dataSemaphore];
        } @catch (NSException *exception) {
            [self stopParseWithException:exception];
        }
        if (!self.data.length) {
            return;
        }
        self.curFileIndexModel.offset = offset;
        [self parseNextFileInfoTypeWithSize:FIELD_BYTES];
    } else {
        self.canContinue = NO;
    }
}

- (void)parseFileIndexInfoSize {
    if (self.infoType == ParseFileIndexInfoTypeSize && self.data.length >= self.offset + FIELD_BYTES) {
        uint32_t size = 0;
        @try {
            [self.data getBytes:&size range:NSMakeRange(self.offset, FIELD_BYTES)  withSemaphore:self.dataSemaphore];
        } @catch (NSException *exception) {
            [self stopParseWithException:exception];
        }
        if (!self.data.length) {
            return;
        }
        self.curFileIndexModel.size = size;
        
        // size是每个文件索引结尾数据. 可以保存了
        if (self.curFileIndexModel.filePath) {
            self.fileIndexesDic[self.curFileIndexModel.filePath] = self.curFileIndexModel;
        }
        [self.fileIndexes addObject:self.curFileIndexModel];
        self.curFileIndexModel = nil;
        // 文件索引全部解析完毕. Job Done
        if (self.fileCount == self.fileIndexes.count) {
            self.canContinue = NO;
            self.fileInfo.fileIndexes = self.fileIndexes;
            self.fileInfo.fileIndexesDic = self.fileIndexesDic;
            BDPPkgFileIndexInfo *indexModel = self.fileIndexes.lastObject;
            self.fileInfo.totalSize = indexModel.offset + indexModel.size;
            if (self.completionBlk) {
                self.completionBlk(self.fileInfo, nil);
                self.completionBlk = nil;
            }
            self.fileInfo = nil;
        } else {
            [self parseNextFileInfoTypeWithSize:FIELD_BYTES];
        }
    } else {
        self.canContinue = NO;
    }
}

#pragma mark - Accessor
- (NSData *)availableData {
    return _data;
}

- (int64_t)size {
    return _data.length;
}

- (NSMutableData *)data {
    if(self.enableHeaderParserProtection)
    {
        @synchronized (self) {
            if (!_data) {
                _data = [[NSMutableData alloc] init];
            }
        }
        return _data;
    }
    if (!_data) {
        _data = [[NSMutableData alloc] init];
    }
    return _data;
}

- (dispatch_semaphore_t )dataSemaphore {
    if (self.enableHeaderParserProtection){
        @synchronized (self) {
            if (!_dataSemaphore) {
                _dataSemaphore = dispatch_semaphore_create(1);
                BDPLogInfo(@"BDPPkgHeaderParser dataSemaphore :%@", _dataSemaphore);
            }
        }
        return _dataSemaphore;
    }
    return nil;
}

- (NSMutableArray<BDPPkgFileIndexInfo *> *)fileIndexes {
    if(self.enableHeaderParserProtection) {
        @synchronized (self) {
            if (!_fileIndexes) {
                _fileIndexes = [[NSMutableArray<BDPPkgFileIndexInfo *> alloc] init];
            }
        }
        return _fileIndexes;
    }
    if (!_fileIndexes) {
        _fileIndexes = [[NSMutableArray<BDPPkgFileIndexInfo *> alloc] init];
    }
    return _fileIndexes;
}

- (NSMutableDictionary<NSString *,BDPPkgFileIndexInfo *> *)fileIndexesDic {
    if(self.enableHeaderParserProtection) {
        @synchronized (self) {
            if (!_fileIndexesDic) {
                _fileIndexesDic = [[NSMutableDictionary<NSString *,BDPPkgFileIndexInfo *> alloc] init];
            }
        }
        return _fileIndexesDic;
    }
    if (!_fileIndexesDic) {
        _fileIndexesDic = [[NSMutableDictionary<NSString *,BDPPkgFileIndexInfo *> alloc] init];
    }
    return _fileIndexesDic;
}
@end
