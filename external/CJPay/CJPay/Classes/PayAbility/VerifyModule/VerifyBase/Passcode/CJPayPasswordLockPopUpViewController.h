//
//  CJPayPasswordLockPopUpViewController.h
//  Pods
//
//  Created by 孟源 on 2022/1/11.
//

#import "CJPayPopUpBaseViewController.h"

@class CJPayErrorButtonInfo;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayPasswordLockPopUpViewController : CJPayPopUpBaseViewController

@property (nonatomic, copy) void(^forgetPwdBlock)(void);
@property (nonatomic, copy) void(^cancelBlock)(void);

- (instancetype)initWithButtonInfo:(CJPayErrorButtonInfo *)buttonInfo;

@end

NS_ASSUME_NONNULL_END
