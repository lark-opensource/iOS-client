//
//  CJPaySignPayHeaderView.h
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/6/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayMarketingMsgView;
@class CJPaySignPayTitleView;
@class CJPaySignPayModel;

@interface CJPaySignPayHeaderView : UIView

- (void)updateHeaderViewWithModel:(CJPaySignPayModel *)model;

- (void)updateMarketingMsgWithPayAmount:(NSString *)payAmount voucherMsg:(NSString *)voucherMsg;

@end

NS_ASSUME_NONNULL_END
