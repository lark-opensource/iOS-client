//
//  CJPayOCRUploadResponseModel.m
//  Pods
//
//  Created by bytedance on 2021/11/3.
//

#import "CJPayOCRUploadResponseModel.h"

@implementation CJPayOCRUploadResponseModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"httpCode": @"http_code",
                @"header" : @"header",
                @"response" : @"response"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
