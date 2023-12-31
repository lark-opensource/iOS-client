//
//  BDPayWithDrawResultViewController.h
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import <UIKit/UIKit.h>
#import "CJPayThemeBaseViewController.h"

@class CJPayMerchantInfo;
@class CJPayBDOrderResultResponse;
@class CJPayProcessInfo;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayWithDrawResultViewController : CJPayThemeBaseViewController

@property (nonatomic, copy) NSString *tradeNo;
@property (nonatomic, strong) CJPayMerchantInfo *merchant;
@property (nonatomic, copy) NSDictionary *withdrawResultPageDescDict;
@property (nonatomic, copy) NSString *memberBizOrderNo;

// 前置请求
@property (nonatomic, strong) CJPayBDOrderResultResponse *response;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) CJPayProcessInfo *processInfo;
@property (nonatomic, copy) NSDictionary *preOrderTrackInfo;

@property (nonatomic, copy) void (^closeAction)(void);

+ (void)requestDataWithMerchantInfo:(CJPayMerchantInfo *)merchant
                            tradeNo:(NSString *)tradeNo
                        processInfo:(CJPayProcessInfo *)processInfo
                         completion:(void(^)(NSError *error, CJPayBDOrderResultResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
