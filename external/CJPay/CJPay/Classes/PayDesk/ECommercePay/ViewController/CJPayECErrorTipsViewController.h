//
//  CJPayECErrorTipsViewController.h
//  Pods
//
//  Created by 尚怀军 on 2021/10/22.
//

#import "CJPayPopUpBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPaySubPayTypeIconTipModel;
@interface CJPayECErrorTipsViewController : CJPayPopUpBaseViewController

@property (nonatomic, strong) CJPaySubPayTypeIconTipModel *iconTips;
@property (nonatomic, copy) void(^closeCompletionBlock)(void);

@end

NS_ASSUME_NONNULL_END
