//
//  BDTuring+SMSCode.m
//  BDTuring
//
//  Created by bob on 2021/8/5.
//

#import "BDTuring+SMSCode.h"
#import "BDTuring+Private.h"
#import "BDTuringVerifyResult+Result.h"
#import "BDTuringConfig+SMSCode.h"
#import "BDTuringSendCodeModel.h"
#import "BDTuringCheckCodeModel.h"
#import "BDTuringVerifyModel+Config.h"
#import "NSData+BDTuring.h"
#import "BDTuringSMSCodeResult.h"
#import "BDTuringServiceCenter.h"
#import "BDTNetworkManager.h"
#import "BDTuringUtility.h"
#import "NSDictionary+BDTuring.h"
#import "NSString+BDTuring.h"
#import "BDTuringVerifyModel+Creator.h"

@implementation BDTuring (SMSCode)

- (void)sendCodeWithModel:(BDTuringSendCodeModel *)model {
    if (![model isValid]) {
        [model handleResult:[BDTuringSMSCodeResult failResult]];
        return;
    }
    NSMutableDictionary *postParameters = [self.config sendCodeParameters];
    [model appendCommonKVParameters:postParameters];
    [BDTNetworkManager asyncRequestForURL:model.requestURL
                                   method:@"POST"
                          queryParameters:nil
                           postParameters:postParameters
                                 callback:^(NSData * _Nullable data) {
        NSDictionary *response = [data turing_objectFromJSONData];
        if (!BDTuring_isValidDictionary(response)) {
            [model handleResult:[BDTuringSMSCodeResult failResult]];
            return;
        }
        BDTuringSMSCodeResult *result = [BDTuringSMSCodeResult new];
        result.status = [response turing_integerValueForKey:@"code"];
        result.message = [response turing_stringValueForKey:@"message"];
        NSDictionary *decision = [[[response turing_dictionaryValueForKey:@"data"] turing_stringValueForKey:@"decision"] turing_dictionaryFromJSONString];
        if (decision != nil) {
            BDTuringVerifyModel *verify = [BDTuringVerifyModel parameterModelWithParameter:decision];
            if (verify) {
                verify.callback = ^(BDTuringVerifyResult *r) {
                    if (r.status == BDTuringVerifyStatusOK) {
                        [self sendCodeWithModel:model];
                    } else {
                        result.status = r.status;
                        [model handleResult:result];
                    }
                };
                verify.appID = self.appID;
                [[BDTuringServiceCenter defaultCenter] popVerifyViewWithModel:verify];
            } else {
                [model handleResult:result];
            }
        } else {
            [model handleResult:result];
        }
    } callbackQueue:nil encrypt:NO tagType:BDTNetworkTagTypeManual];
}

- (void)checkCodeWithModel:(BDTuringCheckCodeModel *)model {
    if (![model isValid]) {
        [model handleResult:[BDTuringSMSCodeResult failResult]];
        return;
    }
    NSMutableDictionary *postParameters = [self.config checkCodeParameters];
    [model appendCommonKVParameters:postParameters];
    [BDTNetworkManager asyncRequestForURL:model.requestURL
                                   method:@"POST"
                          queryParameters:nil
                           postParameters:postParameters
                                 callback:^(NSData * _Nullable data) {
        NSDictionary *response = [data turing_objectFromJSONData];
        if (!BDTuring_isValidDictionary(response)) {
            [model handleResult:[BDTuringSMSCodeResult failResult]];
            return;
        }
        
        /*
         JSON TEXT is as follows:
         {
           "code": 0,
           "data":{
              "ticket":"6184ca74910c69c938b2aaa7f3145d3a99984b338"
            },
            "message": "success"
         }
         */
        BDTuringSMSCodeResult *result = [BDTuringSMSCodeResult new];
        result.status = [response turing_integerValueForKey:@"code"];
        result.message = [response turing_stringValueForKey:@"message"];
        result.ticket =  [[response turing_dictionaryValueForKey:@"data"] turing_stringValueForKey:@"ticket"]; //reference to passport response guide: https://bytedance.feishu.cn/wiki/wikcnmLMMJKVnYFR7J2tJtGjJYg#6XvVmB
        [model handleResult:result];
    } callbackQueue:nil encrypt:NO tagType:BDTNetworkTagTypeManual];
}

@end
