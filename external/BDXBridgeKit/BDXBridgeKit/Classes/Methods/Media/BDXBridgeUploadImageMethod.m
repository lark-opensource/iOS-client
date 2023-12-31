//
//  BDXBridgeUploadImageMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeUploadImageMethod.h"

@implementation BDXBridgeUploadImageMethod

- (NSString *)methodName
{
    return @"x.uploadImage";
}

- (Class)paramModelClass
{
    return BDXBridgeUploadImageMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeUploadImageMethodResultModel.class;
}

@end

@implementation BDXBridgeUploadImageMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"url": @"url",
        @"header": @"header",
        @"params": @"params",
        @"mimeType": @"mimeType",
        @"filePath": @"filePath",
    };
}

@end

@implementation BDXBridgeUploadImageMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"response": @"response",
        @"url": @"url",
        @"uri": @"uri",
    };
}

@end
