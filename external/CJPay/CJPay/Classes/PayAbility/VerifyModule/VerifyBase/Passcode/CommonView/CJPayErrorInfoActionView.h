//
//  CJPayCenterErrorView.h
//  Pods
//
//  Created by 孟源 on 2022/1/25.
//

#import <UIKit/UIKit.h>
#import "CJPayStyleButton.h"
#import "CJPayStyleErrorLabel.h"

NS_ASSUME_NONNULL_BEGIN

// ErrorInfoActionView状态
typedef NS_ENUM(NSInteger, CJPayErrorInfoStatusType) {
    CJPayErrorInfoStatusTypeHidden = 0, // 不展示errorInfoActionView
    CJPayErrorInfoStatusTypePasswordInputTips = 1, //展示密码框提示文案，例如“输入支付密码”
    CJPayErrorInfoStatusTypeDowngradeTips = 2, //展示验证方式降级文案，例如“免密不可用，请输入密码”
    CJPayErrorInfoStatusTypePasswordErrorTips = 3, //展示密码错误提示文案，例如“支付密码输入错误”
};

@interface CJPayErrorInfoActionView : UIView

@property (nonatomic, strong) NSString *action;
@property (nonatomic, strong, readonly) CJPayStyleErrorLabel *errorLabel;
@property (nonatomic, strong, readonly) CJPayLoadingButton *verifyItemBtn;
@property (nonatomic, assign, readonly) CJPayErrorInfoStatusType statusType;

- (void)showActionButton:(BOOL)show;
- (void)updateStatusWithType:(CJPayErrorInfoStatusType)status errorText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
