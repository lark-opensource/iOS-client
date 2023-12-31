//
//  CJPayIDCardOCRRequest.m
//  CJPay
//
//  Created by youerwei on 2022/6/21.
//

#import "CJPayIDCardOCRRequest.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKMacro.h"
#import "CJPaySafeManager.h"

@implementation CJPayIDCardOCRRequest

+ (void)startWithScanStatus:(CJPayIDCardOCRScanStatus)scanStatus bizParams:bizParams completion:(void (^)(NSError * _Nonnull, CJPayIDCardOCRResponse * _Nonnull))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:bizParams scanStatus:scanStatus];
    
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayIDCardOCRResponse *response = [[CJPayIDCardOCRResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/ocr_id_photo";
}

+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams scanStatus:(CJPayIDCardOCRScanStatus)scanStatus {
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    NSMutableDictionary *bizContentParams = [bizParams mutableCopy];
    [bizContentParams cj_setObject:[CJPayRequestParam getMergeRiskInfoWithBizParams:bizParams] forKey:@"risk_info"];
    [bizContentParams cj_setObject:[self p_secureRequestParams] forKey:@"secure_request_params"];
    
    NSString *idPhotoTypeStr = @"";
    switch (scanStatus) {
        case CJPayIDCardOCRScanStatusProfileSide:
            idPhotoTypeStr = @"id_photo_front";
            break;
        case CJPayIDCardOCRScanStatusEmblemSide:
            idPhotoTypeStr = @"id_photo_back";
            break;
        default:
            break;
    }
    
    [bizContentParams cj_setObject:idPhotoTypeStr forKey:@"id_photo_type"];
    [requestParams cj_setObject:[bizContentParams cj_toStr] forKey:@"biz_content"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}

+ (NSDictionary *)p_secureRequestParams{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic addEntriesFromDictionary:[CJPaySafeManager secureInfo]];
    [dic cj_setObject:@[@"id_photo"]
               forKey:@"fields"];
    return dic;
}

@end
