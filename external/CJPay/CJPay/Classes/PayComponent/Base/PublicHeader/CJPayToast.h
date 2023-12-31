//
//  CJPayToast.h
//  CJPay
//
//  Created by wangxinhua on 2018/11/5.
//
#import "CJPayProtocolManager.h"
#import "CJPayToastProtocol.h"

#define CJToast [CJPayToast sharedToast]

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayToast : NSObject<CJPayToastProtocol>

+ (instancetype)sharedToast;
+ (void)toastImage:(NSString *)imageName title:(NSString *)title duration:(NSTimeInterval)duration inWindow:(nullable UIWindow *)window;

@end

NS_ASSUME_NONNULL_END
