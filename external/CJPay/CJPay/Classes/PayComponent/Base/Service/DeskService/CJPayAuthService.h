//
//  CJPayAuthService.h
//  CJPay
//
//  Created by wangxiaohong on 2020/9/3.
//

#ifndef CJPayAuthService_h
#define CJPayAuthService_h
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayAuthService <NSObject>

- (void)i_authWith:(nonnull NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayAuthService_h */
