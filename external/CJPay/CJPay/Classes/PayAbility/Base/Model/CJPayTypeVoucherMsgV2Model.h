//
//  CJPayTypeVoucherMsgV2Model.h
//  CJPaySandBox_3
//
//  Created by wangxiaohong on 2023/3/5.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayVoucherTagType) {
    CJPayVoucherTagTypeDefault = 0,  //非组合支付
    CJPayVoucherTagTypeCombine //组合支付
};

@interface CJPayTypeVoucherMsgV2Model : JSONModel

@property (nonatomic, copy) NSArray<NSDictionary *> *tag12; //抖音支付品牌右侧区域营销
@property (nonatomic, copy) NSArray<NSDictionary *> *tag34; //收银台首页营销（具体支付方式右侧或者下方）
@property (nonatomic, copy) NSArray<NSDictionary *> *tag56; //卡列表营销（支付方式下方）

- (NSArray<NSString *> *)cardListVoucherMsgArrayWithType:(CJPayVoucherTagType)type;

@end

NS_ASSUME_NONNULL_END
