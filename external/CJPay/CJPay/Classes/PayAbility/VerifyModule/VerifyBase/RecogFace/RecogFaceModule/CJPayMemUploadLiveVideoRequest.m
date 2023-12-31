//
//  CJPayMemUploadLiveVideoRequest.m
//  CJPaySandBox
//
//  Created by 尚怀军 on 2022/11/21.
//

#import "CJPayMemUploadLiveVideoRequest.h"
#import "CJPayBaseResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayRequestParam.h"
#import "CJPaySafeUtilsHeader.h"

@implementation CJPayMemUploadLiveVideoRequest

+ (void)startWithRequestparams:(NSDictionary *)requestParams
              bizContentParams:(NSDictionary *)bizContentParams
                    completion:(void (^)(NSError * _Nonnull, CJPayBaseResponse * _Nonnull))completionBlock {
    NSMutableDictionary *mutableRequestParams = [self buildBaseParams];
    [mutableRequestParams addEntriesFromDictionary:requestParams];
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionaryWithDictionary:bizContentParams];

    [bizParams cj_setObject:[requestParams cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [bizParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [bizParams cj_setObject:[self p_secureRequestParams:bizContentParams] forKey:@"secure_request_params"];
    
    [mutableRequestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:bizParams]
                                forKey:@"biz_content"];
    [mutableRequestParams addEntriesFromDictionary:[self apiMethod]];
    
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:[mutableRequestParams copy]
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayBaseResponse *response = [[CJPayBaseResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/upload_face_video";
}

+ (NSDictionary *)p_secureRequestParams:(NSDictionary *)contentDic {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic addEntriesFromDictionary:[CJPaySafeManager secureInfo]];
    NSMutableArray *fields = [NSMutableArray array];
    if ([contentDic valueForKeyPath:@"face_video"]) {
        [fields addObject:@"face_video"];
    }
    
    [dic cj_setObject:fields forKey:@"fields"];
    return dic;
}

@end
