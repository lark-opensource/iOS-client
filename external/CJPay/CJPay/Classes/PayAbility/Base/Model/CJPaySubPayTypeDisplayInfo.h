//
//  CJPaySubPayTypeDisplayInfo.h
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/21.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayDefaultChannelShowConfig;
// 前置下单接口返回，用于展示当前支付方式信息（验密页使用）
@interface CJPaySubPayTypeDisplayInfo : JSONModel

@property (nonatomic, copy) NSString *subPayType; //支付方式类型，同CJPaySubPayTypeInfoModel.subPayType
@property (nonatomic, assign) NSInteger index; //支付方式索引，对应CJPaySubPayTypeInfoModel.index
@property (nonatomic, copy) NSString *iconUrl; //支付方式图标
@property (nonatomic, copy) NSString *title; //支付方式标题（例如XX银行卡）
@property (nonatomic, copy) NSString *paymentInfo; //支付方式付款信息（例如月付分期数、服务费信息）

- (CJPayDefaultChannelShowConfig *)buildShowConfig;
@end

NS_ASSUME_NONNULL_END
