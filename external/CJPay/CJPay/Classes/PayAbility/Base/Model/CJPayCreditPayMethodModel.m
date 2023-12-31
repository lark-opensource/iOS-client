//
//  CJPayCreditPayMethodModel.m
//  Pods
//
//  Created by 易培淮 on 2020/11/16.
//

#import "CJPayCreditPayMethodModel.h"
#import "CJPaySDKMacro.h"

@implementation CJPayVoucherModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"voucherNo" : @"voucher_no",
        @"batchNo" : @"batch_no",
        @"promotionProductCode" : @"promotion_product_code",
        @"voucherType" : @"voucher_type",
        @"voucherName" : @"voucher_name",
        @"reduceAmount" : @"reduce_amount",
        @"randomMaxReductAmount" : @"random_max_reduct_amount",
        @"reachedAmount" : @"reached_amount",
        @"usedAmount" : @"used_amount",
        @"label" : @"label"
        
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}



@end


@implementation CJPayVoucherInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"vouchers" : @"vouchers",
        @"vouchersAmount" : @"vouchers_amount",
        @"vouchersMaxAmount" : @"vouchers_max_amount",
        @"vouchersUsedAmount" : @"vouchers_used_amount",
        @"vouchersLabel" : @"vouchers_label",
        @"vouchersChannelNum" : @"vouchers_channel_num",
        @"vouchersPlatNum" : @"vouchers_plat_num",
        @"vouchersRandomNum" : @"vouchers_random_num",
        @"voucherMsgList": @"voucher_msg_list",
        @"orderSubFixedVoucherAmount" : @"order_sub_fixed_voucher_amount",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    CJPayVoucherInfoModel *voucherInfoModel = [CJPayVoucherInfoModel new];
    voucherInfoModel.vouchers = (NSArray<CJPayVoucherModel> *)[[NSArray alloc] initWithArray:self.vouchers copyItems:YES];
    voucherInfoModel.vouchersAmount = self.vouchersAmount;
    voucherInfoModel.vouchersMaxAmount = self.vouchersMaxAmount;
    voucherInfoModel.vouchersUsedAmount = self.vouchersUsedAmount;
    voucherInfoModel.vouchersLabel = [self.vouchersLabel copy];
    voucherInfoModel.vouchersChannelNum = self.vouchersChannelNum;
    voucherInfoModel.vouchersPlatNum = self.vouchersPlatNum;
    voucherInfoModel.vouchersRandomNum = self.vouchersRandomNum;
    voucherInfoModel.voucherMsgList = [self.voucherMsgList copy];
    voucherInfoModel.orderSubFixedVoucherAmount = self.orderSubFixedVoucherAmount;
    return voucherInfoModel;
}

@end


@implementation CJPayCreditPayMethodModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"status" : @"status",
        @"msg" : @"msg",
        @"installment" : @"installment",
        @"fee" : @"fee",
        @"payAmountPerInstallment" : @"pay_amount_per_installment",
        @"totalAmountPerInstallment" : @"total_amount_per_installment",
        @"voucherFeeMsg" : @"voucher_fee_msg",
        @"voucherPlatformMsg" : @"voucher_platform_msg",
        @"iconUrl" : @"icon_url",
        @"voucherInfo" : @"voucher_info",
        @"identityVerifyWay": @"identity_verify_way"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

+ (NSMutableDictionary *)basicDict {
    return [@{@"status" : @"status",
              @"msg" : @"msg",
              @"installment" : @"installment",
              @"fee" : @"fee",
              @"payAmountPerInstallment" : @"pay_amount_per_installment",
              @"totalAmountPerInstallment" : @"total_amount_per_installment",
              @"voucherFeeMsg" : @"voucher_fee_msg",
              @"voucherPlatformMsg" : @"voucher_platform_msg",
              @"iconUrl" : @"icon_url",
              @"voucherInfo" : @"voucher_info",
              @"identityVerifyWay": @"identity_verify_way",
              @"standardRecDesc" : @"standard_rec_desc",
              @"standardShowAmount" : @"standard_show_amount",
              @"firstPageVoucherMsg": @"first_page_voucher_msg"
    } mutableCopy];
}

#pragma mark CJPayDefaultChannelShowConfigBuildProtocol 内部统一model协议
- (NSArray<CJPayDefaultChannelShowConfig *> *)buildShowConfig {
    CJPayDefaultChannelShowConfig *configModel = [CJPayDefaultChannelShowConfig new];
    configModel.iconUrl = self.iconUrl;
    configModel.title = CJPayLocalizedStr(@"信用支付");
    configModel.subTitle = CJPayLocalizedStr(@"子标题");
    configModel.payChannel = self;
    configModel.status = self.status;
    configModel.mark = self.mark;
    configModel.cjIdentify = @"creditPay";
    if (Check_ValidString(self.standardShowAmount)) {
        configModel.payAmount = self.standardShowAmount;
    }
    if (Check_ValidString(self.standardRecDesc)) {
        configModel.payVoucherMsg = self.standardRecDesc;
    }
    configModel.feeVoucher = self.firstPageVoucherMsg;
    
    return @[configModel];
}

#pragma mark CJPayRequestParamsProtocol 支付参数生成协议
- (NSDictionary *)requestNeedParams{
    return @{@"ptcode": self.code ?: @""};
}

@end

