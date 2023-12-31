//
//  CJPayCreditPayMethodModel.h
//  Pods
//
//  Created by 易培淮 on 2020/11/16.
//

#import <JSONModel/JSONModel.h>
#import "CJPayChannelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayVoucherModel : JSONModel

@property (nonatomic, copy) NSString *voucherNo; //券编号
@property (nonatomic, copy) NSString *batchNo; // 券批次编号
@property (nonatomic, copy) NSString *promotionProductCode; //营销产品码
@property (nonatomic, copy) NSString *voucherType; //券类型
@property (nonatomic, copy) NSString *voucherName; //券名称
@property (nonatomic, assign) NSInteger reduceAmount;  //券金额, 单位, 分
@property (nonatomic, assign) NSInteger randomMaxReductAmount; //随机减最大减免金额, 单位, 分
@property (nonatomic, assign) NSInteger reachedAmount; //满减门槛金额, 单位, 分
@property (nonatomic, assign) NSInteger usedAmount; //券使用金额, 单位， 分
@property (nonatomic, copy) NSString *label; //券标签


@end


@protocol CJPayVoucherModel;
@interface CJPayVoucherInfoModel : JSONModel <NSCopying>

@property (nonatomic, copy) NSArray<CJPayVoucherModel> *vouchers; //优惠券
@property (nonatomic, assign) NSInteger vouchersAmount; //单位分,优惠券总金额(如果是随机立减取实际立减金额)
@property (nonatomic, assign) NSInteger vouchersMaxAmount; //优惠券总金额(如果是随机立减取最大立减金额)
@property (nonatomic, assign) NSInteger vouchersUsedAmount; //单位分, 优惠券使用总金额
@property (nonatomic, copy) NSString *vouchersLabel; //优惠券汇总标签
@property (nonatomic, assign) NSInteger vouchersChannelNum; //渠道营销标志 0-无渠道营销；1-单渠道营销；2-两个渠道营销(特别的，储蓄卡和信用卡为两个渠道)
@property (nonatomic, assign) NSInteger vouchersPlatNum; //平台营销标志 0-无平台营销；1-有平台营销(多个平台营销不支持叠加)
@property (nonatomic, assign) NSInteger vouchersRandomNum; //随机营销标志 0-无随机营销；1-有随机营销(多个随机立减不支持叠加)
@property (nonatomic, copy) NSArray<NSString *> *voucherMsgList;
@property (nonatomic, assign) NSInteger orderSubFixedVoucherAmount;//营销优惠金额，随机立减时候不下发

@end


@protocol CJPayVoucherInfoModel;
@interface CJPayCreditPayMethodModel : CJPayChannelModel

@property (nonatomic, copy) NSString *installment;//分期数，1表示不分期
@property (nonatomic, assign) NSInteger fee;//手续费，单位分
@property (nonatomic, assign) NSInteger payAmountPerInstallment;//每期需支付的本金，单位分
@property (nonatomic, assign) NSInteger totalAmountPerInstallment; //每期需要支付的金额
@property (nonatomic, copy) NSString *voucherFeeMsg; //手续费营销文案
@property (nonatomic, copy) NSString *voucherPlatformMsg; //平台营销文案
@property (nonatomic, strong) CJPayVoucherInfoModel *voucherInfo;//营销信息

@property (nonatomic, copy) NSString *standardRecDesc; // 金额营销信息
@property (nonatomic, copy) NSString *standardShowAmount; // 已经减过营销后的支付金额
@property (nonatomic, copy) NSString *firstPageVoucherMsg; // 手续费营销信息

+ (NSMutableDictionary *)basicDict;

@end

NS_ASSUME_NONNULL_END
