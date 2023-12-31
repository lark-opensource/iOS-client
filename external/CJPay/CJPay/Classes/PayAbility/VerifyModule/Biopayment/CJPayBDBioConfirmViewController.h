//
//  CJPayBDBioConfirmViewController.h
//  Pods
//
//  Created by 尚怀军 on 2021/5/17.
//

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBDBioConfirmViewController : CJPayHalfPageBaseViewController

@property (nonatomic, copy) NSString *verifyReasonText;
@property (nonatomic, copy) void(^confirmBlock)(void);

@end

NS_ASSUME_NONNULL_END
