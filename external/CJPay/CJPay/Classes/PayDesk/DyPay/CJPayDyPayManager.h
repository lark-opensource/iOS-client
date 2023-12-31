//
//  CJPayDyPayManager.h
//  CJPay
//
//  Created by xutianxi on 2022/9/22.
//

#import <Foundation/Foundation.h>
#import "CJPayManagerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayHalfPageBaseViewController;
@class CJPayBDCreateOrderResponse;
@class CJPayNameModel;
@interface CJPayDyPayManager: NSObject

@property (nonatomic, weak) CJPayHalfPageBaseViewController *deskVC;  // 3.0 收银台

/**
 * 获取服务实例
 **/
+ (instancetype)sharedInstance;

/**
 关闭收银台
 */
- (void)closePayDesk;

- (void)closePayDeskWithCompletion:(void (^)(BOOL))completion;

/**
 走签约并支付流程，根据不同的参数打开不同样式的收银台
 */
- (void)openDySignPayDesk:(NSDictionary *)params response:(CJPayBDCreateOrderResponse *)response completion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
