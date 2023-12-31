//
//  CJPayBizDeskPlugin.h
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/3/20.
//

#import <Foundation/Foundation.h>
#import "CJPaySDKDefine.h"

@class CJPayCreateOrderResponse;
@class CJPayOrderResultResponse;
NS_ASSUME_NONNULL_BEGIN

@protocol CJPayBizDeskPlugin <NSObject>

//- (UIViewController *)deskVCWithBizParams:(NSDictionary *)bizParams bizUrl:(NSString *)bizUrl response:(CJPayCreateOrderResponse *)response;

- (UIViewController *)deskVCBizParams:(NSDictionary *)bizParams
                               bizurl:(NSString *)bizUrl
                             response:(CJPayCreateOrderResponse *)response
                      completionBlock:(void(^)(CJPayOrderResultResponse *_Nullable resResponse, CJPayOrderStatus orderStatus)) completionBlock;

@end

NS_ASSUME_NONNULL_END
