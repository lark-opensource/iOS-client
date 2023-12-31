//
//  CJPayHalfVerifySMSViewController.h
//  CJPay
//
//  Created by 张海阳 on 2019/6/19.
//

#import <Foundation/Foundation.h>
#import "CJPaySMSInputView.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayHalfVerifySMSHelpViewController.h"
#import "CJPayVerifySMSVCProtocol.h"
#import "CJPayTrackerProtocol.h"
#import "CJPayTimer.h"
#import "CJPayToast.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayVerifyCodeTimerLabel;
@class CJPayVerifyManager;
@class CJPayDefaultChannelShowConfig;
@class CJPayQuickPayUserAgreement;
typedef NS_ENUM(NSUInteger, CJPayVerifySMSBizType) {
    CJPayVerifySMSBizTypePay,
    CJPayVerifySMSBizTypeSign,
};

@interface CJPayHalfVerifySMSViewController : CJPayHalfPageBaseViewController <CJPayVerifySMSVCProtocol>

@property (nonatomic, copy) void(^completeBlock)(BOOL success, NSString *content);
@property (nonatomic, copy) NSString *bankCardID;
@property (nonatomic, strong) CJPayVerifySMSHelpModel *helpModel;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *orderResponse;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *defaultConfig;
@property (nonatomic, copy) NSArray<CJPayQuickPayUserAgreement *> *agreements;
@property (nonatomic, strong) CJPaySMSInputView *smsInputView;
@property (nonatomic, strong) CJPayVerifyCodeTimerLabel *timeView;
@property (nonatomic, weak) CJPayTimer *externTimer;
@property (nonatomic, assign) BOOL textInputFinished;
@property (nonatomic, copy) NSString *signSource; //补签约来源

- (instancetype)initWithAnimationType:(HalfVCEntranceType)animationType withBizType:(CJPayVerifySMSBizType)bizType;


- (void)showHelpInfo:(BOOL)showHelpInfo;

- (void)executeCompletionBlock:(BOOL)result withContent:(NSString *)content;

- (void)postSMSCode:(void (^)(CJPayBaseResponse *))success failure:(void (^)(CJPayBaseResponse * _Nonnull))failure;

- (void)gotoNextStep;

-(void)goToHelpVC;
    
@end

NS_ASSUME_NONNULL_END
