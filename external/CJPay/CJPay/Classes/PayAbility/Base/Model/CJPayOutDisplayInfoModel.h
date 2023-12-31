//
//  CJPayOutDisplayInfoModel.h
//  SandBox
//
//  Created by ZhengQiuyu on 2023/7/24.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN
/*
 各个模式的UI稿： https://www.figma.com/file/C2rtXQ6z8vbxIuIiGGkLvK/%E4%BB%A3%E6%89%A3?type=design&node-id=7415-43343&mode=design&t=VzumDGew4FveOubd-0
 无模式一的图，可将O项目普通支付看作模式1
 */
typedef NS_ENUM(NSInteger, CJPaySignPayCashierStyleType) {
    CJPaySignPayCashierStyleTypeFrontSignPaySimple = 1, // 模式1
    CJPaySignPayCashierStyleTypeFrontSignPayComplex, // 模式2
    CJPaySignPayCashierStyleTypeFrontSignDeductSimple, // 模式3
    CJPaySignPayCashierStyleTypeFrontSignDeductComplex // 模式4
};

@interface CJPayOutDisplayInfoModel : JSONModel

@property (nonatomic, copy) NSString *payAndSignCashierStyle;//签约并支付，追光收银台样式：
@property (nonatomic, copy) NSString *serviceDescName; // 服务名称描述
@property (nonatomic, copy) NSString *serviceDescText; // 服务描述
@property (nonatomic, copy) NSString *realTradeAmount; // 模式3，4时展示在验密页的金额，因为有可能汇总营销会“最高减”
@property (nonatomic, copy) NSString *promotionDesc; // 汇总营销展示
@property (nonatomic, copy) NSString *deductMethodSubDesc; // 扣款方式附加描述
@property (nonatomic, copy) NSString *afterPaySuccessText; // 支付后返展示文案(非营销)
@property (nonatomic, copy) NSString *payTypeText; // 支付方式文案
@property (nonatomic, copy) NSString *templateId; // 模版id

- (CJPaySignPayCashierStyleType)obtainSignPayCashierStyle;

- (BOOL)isShowDeductDetailViewMode;

- (BOOL)isDeductPayMode;

@end

NS_ASSUME_NONNULL_END
