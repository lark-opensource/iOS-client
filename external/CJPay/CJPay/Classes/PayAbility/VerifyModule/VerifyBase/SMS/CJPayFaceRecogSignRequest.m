//
//  CJPayFaceRecogSignRequest.m
//  CJPay
//
//  Created by 尚怀军 on 2020/8/20.
//

#import "CJPayFaceRecogSignRequest.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayBaseResponse.h"

@implementation CJPayFaceRecogSignRequest

+ (void)startWithRequestparams:(NSDictionary *)requestParams
              bizContentParams:(NSDictionary *)bizContentParams
                    completion:(void (^)(NSError * _Nonnull, CJPayBaseResponse * _Nonnull))completionBlock {
    NSMutableDictionary *mutableRequestParams = [self buildBaseParams];
    [mutableRequestParams addEntriesFromDictionary:requestParams];
    [mutableRequestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:bizContentParams] forKey:@"biz_content"];
    [mutableRequestParams addEntriesFromDictionary:[self apiMethod]];
    
    [self startRequestWithUrl:[self buildServerUrl] requestParams:[mutableRequestParams copy] callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayBaseResponse *response = [[CJPayBaseResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/sign_live_detection_agreement";
}

@end
