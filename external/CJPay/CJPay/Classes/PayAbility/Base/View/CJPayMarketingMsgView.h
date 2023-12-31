//
//  CJPayMarketingMsgView.h
//  Pods
//
//  Created by wangxiaohong on 2020/11/13.
//

#import <UIKit/UIKit.h>
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayEnumUtil.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MarketingMsgViewStyle) {
    MarketingMsgViewStyleCompact = 0, //紧凑，电商密码页营销展示
    MarketingMsgViewStyleNormal = 1,  // 普通，电商收银台Bio引导
    MarketingMsgViewStyleDenoiseV2 = 2,  // 字体和大小微调，新样式验密页使用
    MarketingMsgViewStyleMacro = 3, // 宽松，唤端追光首页、结果页展示
};

@interface CJPayMarketingMsgView : UIView

@property (nonatomic, strong, readonly) UIView *priceView;
@property (nonatomic, strong, readonly) UILabel *discountLabel;//营销信息

- (instancetype)initWithViewStyle:(MarketingMsgViewStyle)viewStyle;
- (instancetype)initWithViewStyle:(MarketingMsgViewStyle)viewStyle isShowVoucherMsg:(BOOL)isShowVoucherMsg;

- (void)updateWithModel:(CJPayBDCreateOrderResponse *)model;
- (void)updateWithModel:(CJPayBDCreateOrderResponse *)model isFromSkipPwdConfirm:(BOOL)isFromSkipPwdConfirm;
/**
    营销信息支持删除线，用 ~~ 字符包裹，举例: ”~~原价100~~, 立减 10 元“ ，其中 ”原价100“ 将展示删除线
 */
- (void)updateWithPayAmount:(NSString *)amount voucherMsg:(NSString *)string;
- (void)hideDiscountLabel;
/// 支付中，无营销与有营销一致，错误信息居中显示，discountLabel需要最小高度占位
- (void)setMinHeightForDiscountLabel;
- (void)updatePriceColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
