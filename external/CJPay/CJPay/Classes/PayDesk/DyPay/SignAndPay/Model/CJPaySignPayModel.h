//
//  CJPaySignPayModel.h
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/6/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayBDCreateOrderResponse;
@class CJPayMemAgreementModel;

@interface CJPaySignPayModel : NSObject

@property (nonatomic, strong) NSURL *logoImageURL;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *closePayAmount;
@property (nonatomic, copy) NSString *openPayAmount;
@property (nonatomic, copy) NSString *voucherMsg;

@property (nonatomic, copy) NSString *switchDesc;
@property (nonatomic, copy) NSString *buttonAction;
@property (nonatomic, copy) NSString *buttonDesc;

@property (nonatomic, copy) NSString *serviceDesc; // 服务描述
@property (nonatomic, copy) NSString *nextDeductDate; // 扣款周期描述

@property (nonatomic, copy) NSString *signPaySwitch;// 为none时默认开启，非none时看是否时若是close则默认关闭，若为open则默认开启

@property (nonatomic, strong) NSURL *deductIconImageURL;
@property (nonatomic, copy) NSString *deductMethodDesc;
@property (nonatomic, copy) NSString *deductMethodSubDesc;

@property (nonatomic, copy) NSDictionary *protocolGroupNames;
@property (nonatomic, copy) NSArray<CJPayMemAgreementModel *> *protocolInfo;

- (instancetype)initWithResponse:(CJPayBDCreateOrderResponse *)response;

@end

NS_ASSUME_NONNULL_END
