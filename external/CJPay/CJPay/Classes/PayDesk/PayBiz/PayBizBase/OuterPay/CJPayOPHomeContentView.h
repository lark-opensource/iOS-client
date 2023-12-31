//
//  CJPayOPHomeContentView.h
//  AwemeInhouse
//
//  Created by xutianxi on 2022/3/29.
//

#import "CJPayHomeBaseContentView.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBDPayMainMessageView;
@class CJPayMarketingMsgView;
@interface CJPayOPHomeContentView : CJPayHomeBaseContentView

@property (nonatomic, strong, readonly) CJPayBDPayMainMessageView *tradeMesageView;
@property (nonatomic, strong, readonly) CJPayBDPayMainMessageView *payTypeMessageView;
@property (nonatomic, strong, readonly) CJPayMarketingMsgView *marketingMsgView;
@property (nonatomic, strong, readonly) UILabel *amountDetailLabel;
@end

NS_ASSUME_NONNULL_END
