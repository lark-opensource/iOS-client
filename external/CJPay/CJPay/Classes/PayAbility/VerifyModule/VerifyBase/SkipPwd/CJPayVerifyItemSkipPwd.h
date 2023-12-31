//
//  CJPayVerifyItemSkipPwd.h
//  Pods
//
//  Created by 尚怀军 on 2021/3/8.
//

#import "CJPayVerifyItem.h"
#import "CJPayLoadingManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySkipPwdConfirmHalfPageViewController;
@class CJPayPopUpBaseViewController;
@interface CJPayVerifyItemSkipPwd : CJPayVerifyItem

@property(nonatomic, weak) CJPayPopUpBaseViewController<CJPayBaseLoadingProtocol> *skipPwdVC;
@property(nonatomic, weak) CJPaySkipPwdConfirmHalfPageViewController<CJPayBaseLoadingProtocol> *skipPwdHalfPageVC;

- (void)showSkipPwdConfirmViewControllerWithResponse:(CJPayBDCreateOrderResponse *)response;
- (NSString *)getFromSourceStr;
- (void)confirmButtonClick;
- (void)closeButtonClick;
- (BOOL)shouldShowRetainVC;
- (void)onConfirmActionFromPage;

- (void)retainCloseButtonClick;
- (void)retainOtherVerifyWithWay:(NSString *)otherVerifyWay;
- (CJPayVerifyType)getOtherVerifyType:(NSString *)otherVerifyWay;

//获取降级验证方式埋点类型
- (NSString *)getOtherVerifyTypeTrack:(NSString *)otherVerifyWay;
- (void)pushSkippwdVC:(CJPayPopUpBaseViewController *)vc; //免密确认页展示方法
- (void)pushSkippwdHalfPageVC:(CJPaySkipPwdConfirmHalfPageViewController *)vc;

@end

NS_ASSUME_NONNULL_END
