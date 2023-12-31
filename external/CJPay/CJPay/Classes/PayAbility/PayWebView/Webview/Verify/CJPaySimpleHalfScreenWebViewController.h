//
//  CJPaySimpleHalfScreenWebViewController.h
//  CJPay
//
//  Created by liyu on 2020/7/14.
//

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySimpleHalfScreenWebViewController : CJPayHalfPageBaseViewController

@property (nonatomic, copy, nullable) void (^didTapCloseButtonBlock)(void);

- (instancetype)initWithUrlString:(NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
