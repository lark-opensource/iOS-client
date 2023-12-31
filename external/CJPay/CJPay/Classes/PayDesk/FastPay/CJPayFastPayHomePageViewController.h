//
//  CJPayFastPayHomePageViewController.h
//  Pods
//
//  Created by wangxiaohong on 2022/10/31.
//

#import "CJPayHalfPageBaseViewController.h"

#import "CJPayAPI.h"
#import "CJPayOrderResultResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayFastPayHomePageViewController : CJPayHalfPageBaseViewController

- (instancetype)initWithBizParams:(NSDictionary *)bizParams
                           bizurl:(NSString *)bizUrl
                         delegate:(id<CJPayAPIDelegate>)delegate
                  completionBlock:(nonnull void (^)(CJPayOrderResultResponse * _Nullable, CJPayOrderStatus))completionBlock;

@end

NS_ASSUME_NONNULL_END
