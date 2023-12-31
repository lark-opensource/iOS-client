//
//  CJPayHalfVerifySMSHelpViewController.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/26.
//

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayVerifySMSHelpModel : NSObject

@property(nonatomic, copy) NSString *frontBankCodeName;//前端银行名称
@property(nonatomic, copy) NSString *cardNoMask; //展示卡号
@property (nonatomic, copy) NSString *phoneNum;

@end

@interface CJPayHalfVerifySMSHelpViewController : CJPayHalfPageBaseViewController

@property (nonatomic, strong) CJPayVerifySMSHelpModel *helpModel;
@property (nonatomic, assign) CGFloat designContentHeight;

@end

NS_ASSUME_NONNULL_END
