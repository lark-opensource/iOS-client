//
//  CJPaySkipPwdConfirmHalfPageViewController.h
//  Aweme
//
//  Created by 陈博成 on 2023/5/21.
//

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBDCreateOrderResponse;
@class CJPayBaseVerifyManager;
@class CJPaySkipPwdConfirmModel;

@interface CJPaySkipPwdConfirmHalfPageViewController : CJPayHalfPageBaseViewController <CJPayBaseLoadingProtocol>

@property (nonatomic, strong) CJPayBDCreateOrderResponse *createOrderResponse;
@property (nonatomic, copy) void(^confirmBlock)(void);
@property (nonatomic, copy) void(^checkboxClickBlock)(BOOL);
@property (nonatomic, copy) void(^backCompletionBlock)(void);

@property (nonatomic, weak) CJPayBaseVerifyManager *verifyManager;

- (instancetype)initWithModel:(CJPaySkipPwdConfirmModel *)model;

@end

NS_ASSUME_NONNULL_END
