//
//  CJPaySenselessPlugin.h
//  CJPay
//
//  Created by wangxinhua on 2020/7/12.
//

#ifndef CJPaySenselessPlugin_h
#define CJPaySenselessPlugin_h


@protocol CJPaySenselessPlugin <NSObject>

- (void)i_queryAndSenselessLoginWithMerchantId:(NSString *)merchantId
                               merchantAppId:(NSString *)merchantAppId
                                  completion:(void(^)(BOOL success, NSDictionary *result))completionBlock;

- (void)i_senselessLoginWithAppId:(NSString *)merchantAppId
                     merchantId:(NSString *)merchantId
                         tagAid:(NSString *)tagAid
                      loginMode:(NSString *)loginMode
                       loginExt:(NSString *)loginExt
                     completion:(void(^)(BOOL success, NSDictionary *result))completionBlock;

@end

#endif /* CJPaySenselessPlugin_h */
