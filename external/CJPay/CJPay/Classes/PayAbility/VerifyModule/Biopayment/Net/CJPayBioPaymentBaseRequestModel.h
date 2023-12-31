//
//  CJBDPayBioPaymentBaseRequesttModel.h
//  BDPay
//
//  Created by 易培淮 on 2020/7/17.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayFaceVerifyInfo;

@interface CJPayBioPaymentBaseRequestModel : JSONModel

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *signType;
@property (nonatomic, copy) NSString *sign;
@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *did;
@property (nonatomic, copy) NSString *timestamp;
@property (nonatomic, copy) NSString *smchId;
@property (nonatomic, copy) NSString *verifyType;
@property (nonatomic, strong) CJPayFaceVerifyInfo *verifyInfo; //活体参数，用活体验证开通时才需要
@property (nonatomic, copy) NSString *memberBizOrderNo; //单号，用于后端验证
@property (nonatomic, assign) BOOL isOnlyReturnDeviceType; //不请求接口，仅返回当前设备支持的生物识别类型
@property (nonatomic, weak, nullable) UIViewController *referVC;
@property (nonatomic, copy) NSString *source; //来源页面及开通类型，来自抖音支付阵地页或支付管理页的免密、指纹、面容等

@end

NS_ASSUME_NONNULL_END
