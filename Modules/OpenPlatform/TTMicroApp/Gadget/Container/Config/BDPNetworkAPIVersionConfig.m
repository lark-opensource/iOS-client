//
//  BDPNetworkAPIVersionConfig.m
//  TTMicroApp
//
//  Created by MJXin on 2022/1/26.
//

#import "BDPNetworkAPIVersionConfig.h"

NSString * const requestConfigKey =  @"request";
NSString * const uploadFileConfigKey =  @"uploadFile";
NSString * const downloadFileConfigKey =  @"downloadFile";

@implementation BDPNetworkAPIVersionConfig

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    self = [super initWithDictionary:dict error:err];
    if (self) {
        if (![_requestVersion isKindOfClass:[NSString class]]) {
            _requestVersion = nil;
        }
        if (![_uploadFileVersion isKindOfClass:[NSString class]]) _uploadFileVersion = nil;
        if (![_downloadFileVersion isKindOfClass:[NSString class]]) _downloadFileVersion = nil;
    }
    return self;
}


+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"requestVersion": requestConfigKey,
                                                                  @"uploadFileVersion": uploadFileConfigKey,
                                                                  @"downloadFileVersion": downloadFileConfigKey,
                                                                  }];
}

@end

@implementation NSString(BDPNetworkAPIVersionConfig)
- (BDPNetworkAPIVersionType)networkAPIVersionType {
    if ([self.lowercaseString isEqualToString:@"v2"]) {
        return BDPNetworkAPIVersionTypeV2;
    } else if ([self.lowercaseString isEqualToString:@"v1"]){
        return BDPNetworkAPIVersionTypeV1;
    } else {
        return BDPNetworkAPIVersionTypeUnknown;
    }
}
@end
