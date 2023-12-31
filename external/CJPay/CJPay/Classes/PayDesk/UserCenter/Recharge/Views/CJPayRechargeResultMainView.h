//
// Created by 张海阳 on 2020/3/11.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@class CJPayBDTradeInfo;
@interface CJPayRechargeResultMainView : UIView

@property (nonatomic, copy) NSString *fund;

- (void)updateWithTradeInfo:(CJPayBDTradeInfo *)tradeInfo;

@end

NS_ASSUME_NONNULL_END
