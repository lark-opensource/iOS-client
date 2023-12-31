//
//  CJPayDYManager.h
//  CJPay
//
//  Created by wangxiaohong on 2020/2/13.
//

#import <Foundation/Foundation.h>
#import "CJPayManagerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayHalfPageBaseViewController;
@class CJPayNameModel;
@interface CJPayDYManager: NSObject

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

@end

NS_ASSUME_NONNULL_END
