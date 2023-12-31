//
//  CJPayTradeInfo.h
//  CJPay-Pay
//
//  Created by wangxiaohong on 2020/9/17.
//

#import <JSONModel/JSONModel.h>
#import "CJPaySDKDefine.h"
@class CJPayDouyinTradeInfo;
@class CJPayBDOrderResultResponse;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayTradeInfo : JSONModel

@property (nonatomic, assign) NSInteger amount;
@property (nonatomic, assign) NSInteger realAmount;
@property (nonatomic, assign) NSInteger createTime;
@property (nonatomic, copy) NSString *currency;
@property (nonatomic, assign) NSInteger expireTime;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *merchantName;
@property (nonatomic, copy) NSString *outTradeNo;
@property (nonatomic, assign) NSInteger payTime;
@property (nonatomic, copy) NSString *payType;
@property (nonatomic, copy) NSString *ptCode;
@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSString *tradeDesc;
@property (nonatomic, copy) NSString *tradeName;
@property (nonatomic, copy) NSString *tradeNo;
@property (nonatomic, copy) NSString *tradeTime;
@property (nonatomic, copy) NSString *uid;
@property (nonatomic, assign, readonly) CJPayOrderStatus tradeStatus;
@property (nonatomic, copy) NSString *statInfo;
@property (nonatomic, copy) NSString *bdpayResultDicStr;
@property (nonatomic, strong) CJPayBDOrderResultResponse *bdpayResultResponse;

@end

NS_ASSUME_NONNULL_END
