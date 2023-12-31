//
//  CJPayWithdrawService.h
//  CJPay
//
//  Created by wangxinhua on 2020/7/12.
//

#ifndef CJPayWithdrawService_h
#define CJPayWithdrawService_h
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayWithdrawService <NSObject>

- (void)i_openWithdrawDeskWithUrl:(NSString *_Nullable)withdrawUrl delegate:(nullable id<CJPayAPIDelegate>)delegate;

- (void)i_openH5WithdrawDeskWithParams:(NSDictionary *)params delegate:(nullable id<CJPayAPIDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayWithdrawService_h */
