//
//  CJPayBindCardProtocolView.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/15.
//

#import <UIKit/UIKit.h>
#import "CJPayProtocolListViewController.h"
#import "CJPayCardManageModule.h"
#import "CJPayQuickPayUserAgreement.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayUserInfo;
@interface CJPayBindCardProtocolView : UIView

@property (nonatomic,assign) BOOL isSelected;
@property (nonatomic, copy) void(^agreeCompletion)(void);
@property (nonatomic, copy) void(^protocolClickCompletion)(void);
@property (nonatomic, copy) void(^protocolSelectCompletion)(BOOL);

@property (nonatomic,copy) NSString *merchantId;
@property (nonatomic,copy) NSString *appId;
@property (nonatomic,assign) CJPayCardBindSourceType cardBindSource;
@property (nonatomic,strong) CJPayUserInfo *userInfo;

- (void)updateWithAgreements:(NSArray<CJPayQuickPayUserAgreement *> *)agreements isNeedAgree:(BOOL)isNeedAgree;

- (void)setIsSelected:(BOOL)isSelected;
- (void)protocolLabelTapped;
- (void)gotoProtocolDetail:(BOOL)supportClickMaskBack
        showContinueButton:(BOOL)showContinueButton;

@end

NS_ASSUME_NONNULL_END
