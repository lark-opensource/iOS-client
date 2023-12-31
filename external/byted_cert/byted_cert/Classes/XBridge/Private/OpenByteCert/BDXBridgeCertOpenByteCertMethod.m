//
//  BDXBridgeCertOpenByteCertMethod.m
//  BDXBridgeKit
//
// ❗️❗️ DON'T CHANGE THIS FILE CONTENT ❗️❗️
//

#import "BDXBridgeCertOpenByteCertMethod.h"

#pragma mark - Method


@implementation BDXBridgeCertOpenByteCertMethod

- (NSString *)methodName {
    return @"cert.openByteCert";
}
- (BDXBridgeAuthType)authType {
    return BDXBridgeAuthTypePrivate;
}

- (Class)paramModelClass {
    return BDXBridgeCertOpenByteCertMethodParamModel.class;
}

- (Class)resultModelClass {
    return BDXBridgeCertOpenByteCertMethodResultModel.class;
}

+ (NSDictionary *)metaInfo {
    return @{
        @"TicketID" : @"28874"
    };
}
@end

#pragma mark - Param


@implementation BDXBridgeCertOpenByteCertMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"scene" : @"scene",
        @"flow" : @"flow",
        @"ticket" : @"ticket",
        @"certAppId" : @"certAppId",
        @"faceOnly" : @"faceOnly",
        @"identityName" : @"identityName",
        @"identityCode" : @"identityCode",
        @"extraParams" : @"extraParams",
        @"h5QueryParams" : @"h5QueryParams",

    };
}
+ (NSSet<NSString *> *)requiredKeyPaths {
    return [NSSet setWithArray:@[
        @"scene",
    ]];
}

@end


#pragma mark - Result


@implementation BDXBridgeCertOpenByteCertMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"errorCode" : @"errorCode",
        @"errorMsg" : @"errorMsg",
        @"ticket" : @"ticket",
        @"certStatus" : @"certStatus",
        @"manualStatus" : @"manualStatus",
        @"ageRange" : @"ageRange",
        @"extData" : @"extData",

    };
}

@end
