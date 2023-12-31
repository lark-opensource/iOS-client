//
//  CJPayUnionPaySignInfo.h
//  Pods
//
//  Created by wangxiaohong on 2021/9/29.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayMemberFaceVerifyInfoModel;
@interface CJPayUnionPaySignInfo : JSONModel

@property (nonatomic, copy) NSString *additionalVerifyType;
@property (nonatomic, copy) NSString *actionPageType; // 跳转的下一个页面
@property (nonatomic, copy) NSString *identityVerifyOrderNo; // 二要素鉴权订单号
@property (nonatomic, strong) CJPayMemberFaceVerifyInfoModel *faceVerifyInfoModel;
@property (nonatomic, copy) NSString *unionPaySignStatus;
@property (nonatomic, copy) NSString *displayIcon;
@property (nonatomic, copy) NSString *displayDesc;
@property (nonatomic, copy) NSString *voucherLabel;

@property (nonatomic, assign) BOOL isNeedVerifyLive; //是否需要验活体
@property (nonatomic, assign) BOOL isNeedAuthUnionPay; //是否需要进行云闪付授权

@end

NS_ASSUME_NONNULL_END
