//
//  CJPayTypeVoucherMsgV2Model.m
//  CJPaySandBox_3
//
//  Created by wangxiaohong on 2023/3/5.
//

#import "CJPayTypeVoucherMsgV2Model.h"

#import "CJPayUIMacro.h"

@implementation CJPayTypeVoucherMsgV2Model

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"tag12": @"tag12",
        @"tag34": @"tag34",
        @"tag56": @"tag56"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (NSArray<NSString *> *)cardListVoucherMsgArrayWithType:(CJPayVoucherTagType)type {
    NSMutableArray *results = [NSMutableArray new];
    [self.tag56 enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self p_voucherTagType:obj] == type) {
            [results btd_addObject:[self p_voucherText:obj]];
        }
    }];
    return results;
}

- (CJPayVoucherTagType)p_voucherTagType:(NSDictionary *)dict {
    NSString *eventType = [dict cj_stringValueForKey:@"event_type"];
    if ([eventType isEqualToString:@"default"]) {
        return CJPayVoucherTagTypeDefault;
    }
    if ([eventType isEqualToString:@"combine_pay"]) {
        return CJPayVoucherTagTypeCombine;
    }
    return CJPayVoucherTagTypeDefault;
}

/*label字段设计为一个list的最初原因是，为了兼容富文本表达的样式。当一个单独的标签，同时由字符+图标+url多个部分组成时，label中会包含type不同的多种元素，客户端可以按照顺序将多种元素拼接起来，用于展示。因此label虽然是一个list，但它代表的是一个单独存在的标签。
由于目前暂不存在 text 类型以外的其他展示类型存在，客户端取用标签时，取用第一个 type = text 的标签做展示即可。*/
- (NSString *)p_voucherText:(NSDictionary *)dict {
    NSArray *label = [dict cj_arrayValueForKey:@"label"];
    __block NSString *text = @"";
    [label enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:NSDictionary.class]) {
            if ([[obj cj_stringValueForKey:@"type"] isEqualToString:@"text"]) {
                text = [obj cj_stringValueForKey:@"text"];
                *stop = YES;
            }
        }
    }];
    return text;
}

@end
