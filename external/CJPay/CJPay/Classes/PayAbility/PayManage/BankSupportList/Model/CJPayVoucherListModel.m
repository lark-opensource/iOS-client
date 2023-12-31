//
//  CJPayVoucherListModel.m
//  Pods
//
//  Created by chenbocheng.moon on 2022/10/16.
//

#import "CJPayVoucherListModel.h"

@implementation CJPayVoucherListModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"mixVoucherMsg": @"mix_voucher_msg",
        @"basicVoucherMsg": @"basic_voucher_msg",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
