//
//  CJPayVerifyItemPassword.h
//  CJPay
//
//  Created by 王新华 on 2019/6/27.
//

#import "CJPayVerifyItem.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayVerifyPasswordViewModel;
@class CJPayHalfVerifyPasswordBaseViewController;
@class CJPayHalfVerifyPasswordV2ViewController;
@class CJPayHalfVerifyPasswordV3ViewController;

@interface CJPayVerifyItemPassword : CJPayVerifyItem

@property (nonatomic, strong) CJPayHalfVerifyPasswordBaseViewController *verifyPasscodeVC;
@property (nonatomic, strong) CJPayVerifyPasswordViewModel *viewModel;
@property (nonatomic, strong) CJPayHalfVerifyPasswordV2ViewController *verifyPasscodeVCv2; //新样式验密页
@property (nonatomic, strong) CJPayHalfVerifyPasswordV3ViewController *verifyPasscodeVCv3; //唤端追光，新样式验密页

- (void)createVerifyPasscodeVC;
- (CJPayVerifyPasswordViewModel *)createPassCodeViewModel;
- (void)closeAction;
- (void)cancelFromPasswordLock;
- (BOOL)shouldShowRetainVC;
- (BOOL)isNeedShowOpenBioGuide;
- (BOOL)usePasswordVCWithChooseMethod; // 是否使用新样式验密页
- (void)createVerifyPasscodeVCWithChooseMethod;
- (CJPayVerifyPasswordViewModel *)createVerifyPasswordViewModelWithChooseMethod;

@end

NS_ASSUME_NONNULL_END
