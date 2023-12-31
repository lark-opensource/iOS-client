//
//  CJPayUserCenter.h
//  CJPay
//
//  Created by 王新华 on 3/9/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDUserCenterCode) {
    BDUserCenterCodeSuccess = 200,
    BDUserCenterCodeFailed,
    BDUserCenterCodeCanceled,
    BDUserCenterCodeCustom,
};

@class CJPayBDOrderResultResponse;
// 会员管理
@interface CJPayUserCenter : NSObject

+ (instancetype)sharedInstance;

// 提现余额
- (void)withdrawBalance:(NSDictionary *)bizContentParams completion:(void(^)(BDUserCenterCode resultCode, CJPayBDOrderResultResponse * _Nullable response))completion;

// 充值余额
- (void)rechargeBalance:(NSDictionary *)bizContentParams completion:(void(^)(BDUserCenterCode resultCode, CJPayBDOrderResultResponse * _Nullable response ))completion;

@end

NS_ASSUME_NONNULL_END
