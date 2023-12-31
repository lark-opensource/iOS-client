//
//  CJPayCarrierLoginProtocol.h
//  CJPay-Pods-Aweme
//
//  Created by 尚怀军 on 2020/11/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^CJPayCarrierPhoneNumFetchCompletion)(NSDictionary * _Nullable data, NSError * _Nullable error);


@protocol CJPayCarrierLoginProtocol <NSObject>

// 从运营商获取手机号码信息
- (void)getCarrierPhoneNumWithCompletion:(CJPayCarrierPhoneNumFetchCompletion)completion;

@optional
//拉起登录组件
- (void)outerPayLogin:(void(^)(BOOL isSuccess))comletion;

@end

NS_ASSUME_NONNULL_END
