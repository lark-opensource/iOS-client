//
//  CJPaySkipPwdConfirmViewController.h
//  Pods
//
//  Created by 尚怀军 on 2021/3/8.
//

#import "CJPayPopUpBaseViewController.h"
#import "CJPayBaseVerifyManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySkipPwdConfirmModel;
@interface CJPaySkipPwdConfirmViewController : CJPayPopUpBaseViewController<CJPayBaseLoadingProtocol>

@property (nonatomic, strong) CJPayBDCreateOrderResponse *createOrderResponse;
@property (nonatomic, copy) void(^confirmBlock)(void);
@property (nonatomic, copy) void(^checkboxClickBlock)(BOOL);
@property (nonatomic, copy) void(^backCompletionBlock)(void);

@property (nonatomic, weak) CJPayBaseVerifyManager *verifyManager;

- (instancetype)initWithModel:(CJPaySkipPwdConfirmModel *)model;

@end


NS_ASSUME_NONNULL_END
