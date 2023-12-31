//
//  CJPayPrefetchConfig.m
//  CJPay
//
//  Created by wangxinhua on 2020/5/13.
//

#import "CJPayPrefetchConfig.h"

@implementation CJPayPrefetchRequestModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"api" : @"api",
                @"method" : @"method",
                @"dataType" : @"data_type",
                @"data" : @"data",
                @"dataFields" : @"data_fields",
                @"dataToJSONKeyPaths" : @"data_json_str",
                @"path": @"path",
                @"hosts": @"host",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayPrefetchConfig

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"prefetchDatas" : @"prefetch_data",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (nullable CJPayPrefetchRequestModel *)getRequestModelByUrl:(NSString *)url {
    __block CJPayPrefetchRequestModel *model;
    NSURL *outURL = [NSURL URLWithString:url];
    [self.prefetchDatas enumerateObjectsUsingBlock:^(CJPayPrefetchRequestModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // path和host全匹配，才认为匹配成功
        if ([obj.path isEqualToString:outURL.path] && [obj.hosts containsObject:outURL.host]) {
            model = obj;
            *stop = YES;
        }
    }];
    return model;
}

@end
