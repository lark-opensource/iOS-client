//
//  CJPayProcessInfo.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/21.
//

#import "CJPayProcessInfo.h"
#import "CJPaySDKMacro.h"

@implementation CJPayProcessInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"createTime" : @"create_time",
                @"processId" : @"process_id",
                @"processInfo" : @"process_info",
                @"defaultPayChannel" : @"default_pay_channel"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (BOOL)isValid {
    if (self.processId != nil && self.processId.length > 0) {
        return YES;
    }
    return NO;
}

- (NSDictionary *)dictionaryValue {
    return @{@"create_time": [NSNumber btd_numberWithString:self.createTime]?:@0,
            @"process_id": CJString(self.processId),
            @"process_info": CJString(self.processInfo)};
}

@end
