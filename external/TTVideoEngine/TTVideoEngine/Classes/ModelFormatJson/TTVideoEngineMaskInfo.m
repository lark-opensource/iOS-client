//
//  TTVideoEngineMaskInfo.m
//  Pods
//
//  Created by jiangyue on 2022/7/29.
//

#import "TTVideoEngineMaskInfo.h"
#import "NSObject+TTVideoEngine.h"
#import "TTVideoEngineInfoModel.h"
#import "TTVideoEnginePlayerDefine.h"


extern id checkNSNull(id obj);

@implementation TTVideoEngineMaskInfo
/// Please use @property.

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict {
    if (!jsonDict) return nil;
    
    self = [super init];
    if (self) {
        _version = checkNSNull(jsonDict[@"version"]);
        _maskUrl = checkNSNull(jsonDict[@"barrage_mask_url"]);
        _fileId = checkNSNull(jsonDict[@"file_id"]);
        _filehash = checkNSNull(jsonDict[@"file_hash"]);
        _fileSize = checkNSNull(jsonDict[@"file_size"]);
        _updatedAt = checkNSNull(jsonDict[@"updated_at"]);
        _bitrate = [checkNSNull(jsonDict[@"bitrate"]) integerValue];
        _headLen = [checkNSNull(jsonDict[@"head_len"]) integerValue];
    }
    return self;
}

- (NSInteger)getValueInt:(NSInteger)key {
    switch (key) {
        case VALUE_MASK_HEAD_LEN:
            return _headLen;
        case VALUE_MASK_BITRATE:
            return _bitrate;
        case VALUE_MASK_FILE_SIZE: {
            if (_fileSize && [_fileSize respondsToSelector:@selector(integerValue)]) {
                return [_fileSize integerValue];
            }
            return -1;
        }
        default:
            return -1;
    }
    
}

- (NSString *)getValueStr:(NSInteger)key {
    switch (key) {
        case VALUE_MASK_VERSION:
            return _version;
        case VALUE_MASK_URL:
            return _maskUrl;
        case VALUE_MASK_FILE_HASH:
            return _filehash;
        case VALUE_MASK_FILE_ID:
            return _fileId;
        default:
            return @"";
    }
    
}

- (NSDictionary *)toMediaInfoDict {
    NSMutableDictionary *temDict = [NSMutableDictionary dictionary];
    [temDict setValue:[self getValueStr:VALUE_MASK_FILE_ID] forKey:@"file_id"];
    [temDict setValue:@"mask" forKey:@"media_type"];
    [temDict setValue:_fileSize forKey:@"file_size"];
    [temDict setObject:@([self getValueInt:VALUE_MASK_BITRATE]) forKey:@"bitrate"];
    [temDict setValue:@[[self getValueStr:VALUE_MASK_URL]] forKey:@"urls"];
    [temDict setValue:[self getValueStr:VALUE_MASK_FILE_HASH] forKey:@"file_hash"];
    return temDict.copy;
}

///MARK: - NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

@end
