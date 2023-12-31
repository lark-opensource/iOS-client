//
//  CJPayOCRFileResponseModel.m
//  Pods
//
//  Created by bytedance on 2021/11/3.
//

#import "CJPayOCRFileResponseModel.h"

@implementation CJPayOCRFileResponseModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"mediaType": @"media_type",
                @"size" : @"size",
                @"filePath" : @"file_path",
                @"metaFile" : @"meta_file",
                @"metaFilePrefix": @"meta_file_prefix",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
