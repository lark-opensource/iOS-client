//
// Created by 张海阳 on 2019/10/20.
//

#import "CJPayPassKitBaseResponse.h"
#import "CJPayErrorButtonInfo.h"
#import <JSONModel/JSONModel.h>


@implementation CJPayPassKitBaseResponse

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:self.basicDict];
}

+ (NSDictionary *)basicDict {
    NSMutableDictionary *dict = [super.basicDict mutableCopy];
    [dict addEntriesFromDictionary:@{
        @"buttonInfo": @"response.button_info",
    }];
    return dict;
}

- (BOOL)isSuccess {
    return [self.status isEqualToString:@"SUCCESS"] && [self.code isEqualToString:@"MP000000"];
}

@end
