//
//  CJPayBizWebViewController+Biz.h
//  CJPay
//
//  Created by 王新华 on 10/15/19.
//

#import "CJPayBizWebViewController.h"
#import "CJPayH5DeskModule.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBizWebViewController(Biz)

+ (CJPayBizWebViewController *)buildWebBizVC:(CJH5CashDeskStyle)cashDeskStyle
                                    finalUrl:(NSString *)finalUrl
                                  completion:(nullable void(^)(id))closeCallBack;

@end

NS_ASSUME_NONNULL_END
