//
//  CJPayIDCardOCRResponse.m
//  CJPay
//
//  Created by youerwei on 2022/6/21.
//

#import "CJPayIDCardOCRResponse.h"

@implementation CJPayIDCardOCRResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
                                    @"flowNo" : @"response.flow_no",
                                    @"idName" : @"response.id_name",
                                    @"idCode" : @"response.id_code",
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
