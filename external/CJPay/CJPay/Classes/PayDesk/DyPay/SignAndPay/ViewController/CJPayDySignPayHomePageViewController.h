//
//  CJPayDySignPayHomePageViewController.h
//  CJPaySandBox
//
//  Created by 郑秋雨 on 2023/3/2.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayFullPageBaseViewController.h"

typedef void(^CJPayRequestLynxResult)(BOOL isSuccess, NSError * _Nullable loadError);
@class CJPayBDCreateOrderResponse;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDySignPayHomePageViewController : CJPayFullPageBaseViewController

@property (nonatomic, copy) CJPayRequestLynxResult resultBlock;

- (instancetype)initPageWithParams:(NSDictionary * __nullable)params response:(CJPayBDCreateOrderResponse *)response ;
@end

NS_ASSUME_NONNULL_END
