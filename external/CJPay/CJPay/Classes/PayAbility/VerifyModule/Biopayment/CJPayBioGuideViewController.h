//
//  CJPayBioGuideViewController.h
//  CJPay
//
//  Created by renqiang on 2020/9/6.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayImageLabelStateView.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBaseVerifyManager;
@class CJPayBioPaymentInfo;
@interface CJPayBioGuideViewController : CJPayHalfPageBaseViewController<CJPayBaseLoadingProtocol>

@property (nonatomic, strong) CJPayBaseVerifyManager *manager;
@property (nonatomic, assign) BOOL isTradeCreateAgain;

+ (instancetype)createWithWithParams:(NSDictionary *)params
                     completionBlock:(void (^)(void))completionBlock;

- (instancetype)initWithPaymentInfo:(CJPayBioPaymentInfo *)bioPaymentInfo completionBlock:(void (^)(void))completionBlock;

@end

NS_ASSUME_NONNULL_END
