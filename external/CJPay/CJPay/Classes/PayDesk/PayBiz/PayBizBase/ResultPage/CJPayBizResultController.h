//
//  CJPayBizResultController.h
//  aweme_transferpay_opt
//
//  Created by shanghuaijun on 2023/6/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayHomePageViewController;
@class CJPayCreateOrderResponse;
@class CJPayOrderResultResponse;
@class CJPayDefaultChannelShowConfig;
@interface CJPayBizResultController : NSObject

@property (nonatomic, weak) CJPayHomePageViewController *homeVC;
@property (nonatomic, strong) CJPayCreateOrderResponse *bizCreateOrderResponse;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *showConfig;
@property (nonatomic, copy) NSDictionary *trackParams;
@property (nonatomic, copy, nullable) void(^resultPageWillAppearBlock)(void);

- (void)showResultPageWithOrderResultResponse:(CJPayOrderResultResponse *)bizOrderResultResponse
                              completionBlock:(void(^)(void))completionBlock;

@end

NS_ASSUME_NONNULL_END
