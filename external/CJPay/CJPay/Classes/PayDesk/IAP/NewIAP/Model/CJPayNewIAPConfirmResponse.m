//
//  CJPayNewIAPSK1ConfirmResponse.m
//  Pods
//
//  Created by 尚怀军 on 2022/3/8.
//

#import "CJPayNewIAPConfirmResponse.h"
#import "CJPayNewIAPConfirmModel.h"

@implementation CJPayNewIAPConfirmResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
        @"finishTransaction" : @"response.finish_transaction",
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dict];
}

- (CJPayNewIAPConfirmModel *)toNewIAPConfirmModel {
    CJPayNewIAPConfirmModel *model = [CJPayNewIAPConfirmModel new];
    model.code = self.code;
    model.msg = self.msg;
    model.status = self.status;
    model.finishTransaction = self.finishTransaction;
    return model;
}


@end
