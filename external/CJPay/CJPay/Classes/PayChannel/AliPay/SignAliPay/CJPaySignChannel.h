//
//  CJPaySignChannel.h
//  arkcrypto-minigame-iOS
//
//  Created by mengxin on 2021/3/10.
//  签约支付宝免密支付
//

#import "CJPayBasicChannel.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPaySignAliPayModule.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySignChannel : CJPayBasicChannel

@end


@class AFServiceResponse;
@interface CJPaySignChannel(AliPaySDKSign)<CJPaySignAliPayModule>

- (void)handleSignAliPayResponseWith:(AFServiceResponse *)response;
- (void)signActionWithDataDict:(NSDictionary *)dataDict completionBlock:(void(^)(NSDictionary *resultDic))completionBlock;


@end

NS_ASSUME_NONNULL_END

