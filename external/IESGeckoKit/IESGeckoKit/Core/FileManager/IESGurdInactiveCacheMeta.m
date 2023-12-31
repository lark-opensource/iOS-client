//
//  IESGurdInactiveCacheMeta.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/9.
//

#import "IESGurdInactiveCacheMeta.h"

#import <objc/message.h>
#import <objc/runtime.h>
#import "IESGeckoDefines+Private.h"

@implementation IESGurdInactiveCacheMeta

#pragma mark - IESGurdMetadataProtocol

+ (instancetype)metaWithData:(NSData *)data
{
    IESGurdInactiveCacheMeta *meta = [[self alloc] init];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    meta->_accessKey = dictionary[@"accessKey"];
    meta->_channel = dictionary[@"channel"];
    meta->_md5 = dictionary[@"md5"];
    meta->_decompressMD5 = dictionary[@"decompressMD5"];
    meta->_version = [dictionary[@"version"] unsignedLongLongValue];
    meta->_packageID = [dictionary[@"packageID"] unsignedLongLongValue];
    meta->_patchID = [dictionary[@"patchID"] unsignedLongLongValue];
    meta->_localVersion = [dictionary[@"localVersion"] unsignedLongLongValue];
    meta->_packageType = [dictionary[@"packageType"] intValue];
    meta->_fromPatch = [dictionary[@"fromPatch"] boolValue];
    meta->_isZstd = [dictionary[@"isZstd"] boolValue];
    meta->_fileName = dictionary[@"fileName"];
    meta->_groupName = dictionary[@"groupName"];
    meta->_groups = dictionary[@"groups"];
    meta->_logId = dictionary[@"logId"];
    meta->_packageSize = [dictionary[@"packageSize"] unsignedLongLongValue];
    meta->_patchPackageSize = [dictionary[@"patchPackageSize"] unsignedLongLongValue];
    
    IESGurdUpdateStatisticModel *model = [[IESGurdUpdateStatisticModel alloc] init];
    meta->_updateStatisticModel = model;
    model.startTime = [NSDate date];
    model.createByReboot = YES;
    model.patchID = meta->_patchID;
    IESGurdUpdateStageModel *stageModel = [model getStageModel:YES isPatch:meta->_fromPatch];
    stageModel.startTime = [NSDate date];

    return meta;
}

- (NSData *)binaryData
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"accessKey"] = self->_accessKey;
    dictionary[@"channel"] = self->_channel;
    dictionary[@"md5"] = self->_md5;
    dictionary[@"decompressMD5"] = self->_decompressMD5;
    dictionary[@"version"] = @(self->_version);
    dictionary[@"packageID"] = @(self->_packageID);
    dictionary[@"patchID"] = @(self->_patchID);
    dictionary[@"localVersion"] = @(self->_localVersion);
    dictionary[@"packageType"] = @(self->_packageType);
    dictionary[@"fromPatch"] = @(self->_fromPatch);
    dictionary[@"isZstd"] = @(self->_isZstd);
    dictionary[@"fileName"] = self->_fileName;
    dictionary[@"groupName"] = self->_groupName;
    dictionary[@"groups"] = self->_groups;
    dictionary[@"logId"] = self->_logId;
    dictionary[@"packageSize"] = @(self->_packageSize);
    dictionary[@"patchPackageSize"] = @(self->_patchPackageSize);
    return [NSJSONSerialization dataWithJSONObject:[dictionary copy] options:0 error:NULL];
}

- (void)putDataToDict:(NSMutableDictionary *)dict
{
    dict[@"access_key"] = self.accessKey;
    dict[@"id"] = @(self.packageID);
    dict[@"is_zstd"] = self.isZstd ? @(1) : @(0);
    dict[@"channel"] = self.channel;
    
    if (self.localVersion > 0) dict[@"local_version"] = @(self.localVersion);
    if (self.groupName.length > 0) dict[@"group_name"] = self.groupName;
    if (self.logId.length > 0) dict[@"x_tt_logid"] = self.logId;
}

- (NSString *)metadataIdentity
{
    return [NSString stringWithFormat:@"%@-%@", self.accessKey, self.channel];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {        
        IES_DECODE_STRING(aDecoder, accessKey);
        IES_DECODE_STRING(aDecoder, channel);
        IES_DECODE_STRING(aDecoder, md5);
        IES_DECODE_INT(aDecoder, version);
        IES_DECODE_INT(aDecoder, packageID);
        IES_DECODE_INT(aDecoder, patchID);
        IES_DECODE_INT(aDecoder, packageType);
        IES_DECODE_BOOL(aDecoder, fromPatch);
        IES_DECODE_STRING(aDecoder, fileName);
        IES_DECODE_STRING(aDecoder, logId);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    IES_ENCODE_OBJECT(coder, accessKey);
    IES_ENCODE_OBJECT(coder, channel);
    IES_ENCODE_OBJECT(coder, md5);
    IES_ENCODE_NUMBER(coder, version);
    IES_ENCODE_NUMBER(coder, packageID);
    IES_ENCODE_NUMBER(coder, patchID);
    IES_ENCODE_NUMBER(coder, packageType);
    IES_ENCODE_NUMBER(coder, fromPatch);
    IES_ENCODE_OBJECT(coder, fileName);
    IES_ENCODE_OBJECT(coder, logId);
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"ak:%@, channel:%@, version:%llu, fromPatch:%d, isZstd:%d",
            self.accessKey, self.channel, self.version, self.fromPatch, self.isZstd];
}

@end
