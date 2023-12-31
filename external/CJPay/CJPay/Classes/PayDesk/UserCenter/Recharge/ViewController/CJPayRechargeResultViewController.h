//
// Created by 张海阳 on 2020/3/11.
//

#import <Foundation/Foundation.h>
#import "CJPayThemeBaseViewController.h"

@class CJPayDiscountBanner;
@protocol CJPayHomeVCProtocol;
@class CJPayBDTradeInfo;
@class CJPayMerchantInfo;
@class CJPayBDOrderResultResponse;


NS_ASSUME_NONNULL_BEGIN

@interface CJPayRechargeResultViewController : CJPayThemeBaseViewController

@property (nonatomic, strong) CJPayMerchantInfo *merchant;
@property (nonatomic, strong) CJPayBDTradeInfo *tradeInfo;
@property (nonatomic, assign) NSInteger closeAfterTime;
@property (nonatomic, copy) NSString *memberBizOrderNo;
@property (nonatomic, strong) CJPayBDOrderResultResponse *response;
@property (nonatomic, copy) NSDictionary *preOrderTrackInfo;

@property (nonatomic, copy) void (^closeAction)(void);

@end

NS_ASSUME_NONNULL_END
