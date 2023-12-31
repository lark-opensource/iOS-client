//
//  IESGurdInternalPackageMetaInfo.m
//  BDAssert
//
//  Created by 陈煜钏 on 2020/9/17.
//

#import "IESGurdInternalPackageMetaInfo+Private.h"

#import "IESGeckoDefines+Private.h"

@implementation IESGurdInternalPackageMetaInfo

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        IES_DECODE_STRING(aDecoder, accessKey);
        IES_DECODE_STRING(aDecoder, channel);
        IES_DECODE_INT(aDecoder, packageId);
        IES_DECODE_STRING(aDecoder, bundleName);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    IES_ENCODE_OBJECT(coder, accessKey);
    IES_ENCODE_OBJECT(coder, channel);
    IES_ENCODE_NUMBER(coder, packageId);
    IES_ENCODE_OBJECT(coder, bundleName);
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end
