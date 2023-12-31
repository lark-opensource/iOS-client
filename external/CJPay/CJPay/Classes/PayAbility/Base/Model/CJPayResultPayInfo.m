//
//  CJPayResultPayInfo.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/27.
//

#import "CJPayResultPayInfo.h"

@implementation CJPayResultPayInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"amount" : @"amount",
                @"payType" : @"paytype",
                @"desc": @"desc",
                @"halfScreenDesc": @"half_screen_desc",
                @"name": @"name",
                @"typeMark" : @"type_mark",
                @"colorType": @"color_type",
                @"payTypeShowName": @"pay_type_show_name"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
