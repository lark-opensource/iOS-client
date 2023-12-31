//
//  IESGurdActivePackageMeta.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/28.
//

#import "IESGurdActivePackageMeta.h"

#import <objc/message.h>
#import "IESGeckoDefines+Private.h"

@implementation IESGurdActivePackageMeta

#pragma mark - IESGurdMetadataProtocol

+ (instancetype)metaWithData:(NSData *)data
{
    IESGurdActivePackageMeta *meta = [[self alloc] init];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    meta->_accessKey = dictionary[@"accessKey"];
    meta->_channel = dictionary[@"channel"];
    meta->_md5 = dictionary[@"md5"];
    meta->_version = [dictionary[@"version"] unsignedLongLongValue];
    meta->_packageID = [dictionary[@"packageID"] unsignedLongLongValue];
    meta->_packageType = [dictionary[@"packageType"] intValue];
    meta->_lastUpdateTimestamp = [dictionary[@"lastUpdateTimestamp"] longLongValue];
    meta->_lastReadTimestamp = [dictionary[@"lastReadTimestamp"] longLongValue];
    if (meta->_lastReadTimestamp == 0) {
        meta->_lastReadTimestamp = meta->_lastUpdateTimestamp;
    }
    meta->_packageSize = [dictionary[@"packageSize"] unsignedLongLongValue];
    
    meta->_isUsed = [dictionary[@"isUsed"] boolValue];
    meta->_groupName = dictionary[@"groupName"];
    meta->_groups = dictionary[@"groups"];
    return meta;
}

- (NSData *)binaryData
{
    if (self->_lastReadTimestamp == 0) {
        self->_lastReadTimestamp = self->_lastUpdateTimestamp;
    }
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"accessKey"] = self->_accessKey;
    dictionary[@"channel"] = self->_channel;
    dictionary[@"md5"] = self->_md5;
    dictionary[@"version"] = @(self->_version);
    dictionary[@"packageID"] = @(self->_packageID);
    dictionary[@"packageType"] = @(self->_packageType);
    dictionary[@"lastUpdateTimestamp"] = @(self->_lastUpdateTimestamp);
    dictionary[@"lastReadTimestamp"] = @(self->_lastReadTimestamp);
    dictionary[@"packageSize"] = @(self->_packageSize);
    dictionary[@"isUsed"] = @(self->_isUsed);
    dictionary[@"groupName"] = self->_groupName;
    dictionary[@"groups"] = self->_groups;
    return [NSJSONSerialization dataWithJSONObject:[dictionary copy] options:0 error:NULL];
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
        IES_DECODE_INT(aDecoder, packageType);
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
    IES_ENCODE_NUMBER(coder, packageType);
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end
