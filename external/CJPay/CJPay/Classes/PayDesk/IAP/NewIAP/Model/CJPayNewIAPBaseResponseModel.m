//
//  CJPayNewIAPBaseResponseModel.m
//  CJPay
//
//  Created by 尚怀军 on 2022/2/22.
//

#import "CJPayNewIAPBaseResponseModel.h"

@implementation CJPayNewIAPBaseResponseModel

- (BOOL)isSuccess {
    if (self.code && self.code.length > 0) {
        NSArray *successCodes = @[@"UM0000", @"MB0000", @"CA0000", @"PP0000", @"PP000000", @"CI0000", @"PC0000"];
        return [successCodes containsObject:self.code];
    } else {
        return NO;
    }
}

@end
