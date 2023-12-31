//
//  CJPayHomeBytePayContentView.h
//  Pods
//
//  Created by wangxiaohong on 2021/4/13.
//

#import "CJPayHomeBaseContentView.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayMarketingMsgView;
@interface CJPayBytePayHomeContentView : CJPayHomeBaseContentView

@property (nonatomic, strong, readonly) CJPayMarketingMsgView *marketingMsgView;
@property (nonatomic, strong, readonly) UILabel *orderDetailLabel;
// 更新金额区的金额和营销信息
- (void)refreshPriceViewWithAmount:(NSString *)amount voucher:(nullable NSString *)voucher;

@end

NS_ASSUME_NONNULL_END
