//
//  CJPayRetainMsgModel.m
//  Pods
//
//  Created by youerwei on 2022/2/7.
//

#import "CJPayRetainMsgModel.h"

@implementation CJPayRetainMsgModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"leftMsg": @"left_msg",
        @"leftMsgType": @"left_msg_type",
        @"rightMsg": @"right_msg",
        @"topLeftMsg": @"top_left_msg",
        @"voucherType": @"voucher_type",
        @"topLeftPosition": @"top_left_position"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
