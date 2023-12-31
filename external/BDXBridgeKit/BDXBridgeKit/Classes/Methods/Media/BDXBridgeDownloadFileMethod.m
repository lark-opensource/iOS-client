//
//  BDXBridgeDownloadFileMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeDownloadFileMethod.h"

@implementation BDXBridgeDownloadFileMethod

- (NSString *)methodName
{
    return @"x.downloadFile";
}

- (Class)paramModelClass
{
    return BDXBridgeDownloadFileMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeDownloadFileMethodResultModel.class;
}

@end

@implementation BDXBridgeDownloadFileMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"url": @"url",
        @"header": @"header",
        @"params": @"params",
        @"extension": @"extension",
    };
}

@end

@implementation BDXBridgeDownloadFileMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"httpCode": @"httpCode",
        @"header": @"header",
        @"filePath": @"filePath",
    };
}

@end
