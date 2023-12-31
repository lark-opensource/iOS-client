//
//  CJPayOuterAuthViewController.h
//  CJPay
//
//  Created by 尚怀军 on 2020/9/24.
//

#import "CJPayFullPageBaseViewController.h"
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

// 外部App拉起抖音支付收银台
@interface CJPayOuterAuthViewController : CJPayFullPageBaseViewController

@property (nonatomic, copy) NSDictionary *schemaParams;
@property (nonatomic, weak) id<CJPayAPIDelegate> apiDelegate;

@end

NS_ASSUME_NONNULL_END
