//
//  BDTuringVerifyView+Result.m
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringVerifyView+Result.h"
#import "NSDictionary+BDTuring.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringVerifyModel+Result.h"
#import "BDTuringVerifyResult+Result.h"

@implementation BDTuringVerifyView (Result)

- (void)handleCallbackStatus:(BDTuringVerifyStatus)status {
    [self.model handleResultStatus:status];
}

- (void)handleCallbackResult:(NSDictionary *)params {
    BDTuringVerifyStatus status = [params turing_integerValueForKey:kBDTuringVerifyParamResult];
    NSString *token = [params turing_stringValueForKey:kBDTuringToken];
    NSString *mobile = [params turing_stringValueForKey:kBDTuringMobile];
    BDTuringVerifyResult *result = [BDTuringVerifyResult new];
    result.status =status;
    result.mobile = mobile;
    result.token = token;
    [self.model handleResult:result];
}

@end
