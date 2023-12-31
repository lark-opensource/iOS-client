//
//  CJPayDYLoginDataProvider.h
//  CJPay
//
//  Created by 徐波 on 2020/4/9.
//

#import <Foundation/Foundation.h>
#import "CJUniversalLoginManager.h"
#import "CJPayBDCreateOrderRequest.h"
#import "CJPayBDCreateOrderResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDYLoginDataProvider : NSObject<CJUniversalLoginProviderDelegate>

@property (nonatomic, strong) CJPayBDCreateOrderResponse *response;
@property (nonatomic, copy) NSDictionary *bizContentParams;
@property (nonatomic, assign) BOOL disableLoading;

- (instancetype)initWithBizContentParams:(NSDictionary *)bizContentParams
                         appId:(NSString *)appId
                    merhcantId:(NSString *)merchantId;

@end

NS_ASSUME_NONNULL_END
