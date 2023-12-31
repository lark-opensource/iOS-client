//
// Created by 张海阳 on 2020/2/20.
//

#import "CJPayCashDeskSendSMSResponse.h"
#import "CJPayProcessInfo.h"
#import "CJPayErrorButtonInfo.h"


@implementation CJPayCashDeskSendSMSResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *keyDict = [self.basicDict mutableCopy];
    [keyDict addEntriesFromDictionary:@{
            @"desc": @"response.desc",
            @"mobileMask": @"response.mobile",
            @"buttonInfo": @"response.button_info"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:keyDict];
}

@end
