//
//  CJPayNativeWithdrawService.h
//  CJPay
//
//  Created by wangxinhua on 2020/7/12.
//

#ifndef CJPayNativeWithdrawService_h
#define CJPayNativeWithdrawService_h
#import "CJPaySDKDefine.h"

@protocol CJPayNativeWithdrawService <NSObject>

- (void)i_nativeOpenWithdrawDeskWithUrl:(nonnull NSString *)withdrawUrl delegate:(nullable id<CJPayAPIDelegate>)delegate;

@end


#endif /* CJPayNativeWithdrawService_h */
