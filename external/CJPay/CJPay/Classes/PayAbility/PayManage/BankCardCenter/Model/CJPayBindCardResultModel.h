//
//  CJPayBindCardResultModel.h
//  CJPay
//
//  Created by 尚怀军 on 2020/3/12.
//

#import <Foundation/Foundation.h>
#import "CJPayCardManageModule.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayMemBankInfoModel;
@interface CJPayBindCardResultModel : NSObject

@property (nonatomic, assign) CJPayBindCardResult result;
@property (nonatomic, strong) CJPayMemBankInfoModel *bankCardInfo;
@property (nonatomic, assign) BOOL isSyncUnionCard;
@property (nonatomic, assign) BOOL isLynxBindCard;
// 绑卡并支付会有这两个字段
@property (nonatomic, copy, nullable) NSString *signNo;
@property (nonatomic, copy, nullable) NSString *token;
@property (nonatomic, copy, nullable) NSString *failMsg;

// 绑卡订单号，一键绑卡时为一键绑卡订单号，普通绑卡时为普通绑卡订单号
@property (nonatomic, copy) NSString *memberBizOrderNo;

@end

NS_ASSUME_NONNULL_END
