//
//  CJPayOuterBaseViewController.m
//  Aweme
//
//  Created by wangxiaohong on 2022/10/11.
//

#import "CJPayOuterBaseViewController.h"

#import "CJPayHomePageViewController.h"
#import "CJPayAlertController.h"
#import "CJPayAlertUtil.h"
#import "CJPayCommonTrackUtil.h"
#import "UIImageView+CJPay.h"
#import "CJPayOuterPayUtil.h"
#import "CJPayAlertUtil.h"
#import "CJPayRequestParam.h"
#import "CJPayOuterPayUtil.h"
#import "CJPayPrivacyMethodUtil.h"

@interface CJPayOuterBaseViewController ()

@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UILabel *userNicknameLabel; // 用户昵称
@property (nonatomic, strong) UIImageView *userAvatarImageView; // 用户头像
@property (nonatomic, strong) UIView *userInfoView; //承载用户昵称和用户头像

@property (nonatomic, strong) UILabel *singleLineUserNicknameLabel; // 用户昵称
@property (nonatomic, strong) UIImageView *singleLineUserAvatarImageView; // 用户头像
@property (nonatomic, strong) UIView *singleLineUserInfoView; //承载用户昵称和用户头像

@property (nonatomic, assign) BOOL isFromApp; // 判断是从 App 还是 safari 发起的支付
@property (nonatomic, assign) BOOL isViewDidAppear; // 判断VC是否已经显示过了
@property (nonatomic, copy) NSString *jumpBackUrlStr;
@property (nonatomic, copy) NSDictionary *baseTrackParams;

@end

@implementation CJPayOuterBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isViewDidAppear = NO;
    [self p_setupUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (NO == self.isViewDidAppear) {
        [self p_checkValid];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"aweme.cold_launch.third_page.show_end.notification" object:nil];
    }
    self.isViewDidAppear = YES;
}

#pragma mark - Public methods
- (void)didFinishParamsCheck:(BOOL)isSuccess {
    CJPayLogInfo(@"子类实现");
}

- (void)back {
    [self closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeCancel];
}

- (void)alertRequestErrorWithMsg:(NSString *)alertText
                       clickAction:(void(^)(void))clickAction {
    [CJPayAlertUtil customSingleAlertWithTitle:alertText content:@"" buttonDesc:CJPayLocalizedStr(@"知道了") actionBlock:^{
        CJ_CALL_BLOCK(clickAction);
    } useVC:self];
    
    NSMutableDictionary *trackParams = [NSMutableDictionary new];
    if (Check_ValidDictionary(self.baseTrackParams)) {
        [trackParams addEntriesFromDictionary:self.baseTrackParams];
        NSTimeInterval currentTimestamp = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
        NSTimeInterval startTimestamp = [self.baseTrackParams cj_doubleValueForKey:@"client_base_time"];
        if (startTimestamp > 100000) {
            [trackParams cj_setObject:@((int)(currentTimestamp-startTimestamp)) forKey:@"client_duration"];
        }
    }
    [trackParams cj_setObject:CJString(alertText) forKey:@"error_msg"];

    [CJTracker event:@"wallet_cashier_douyin_to_pay_error_pop" params:trackParams];
}

- (void)closeCashierDeskAndJumpBackWithResult:(CJPayDypayResultType)resultType {
    [CJPayOuterPayUtil closeCashierDeskVC:self signType:self.isFromApp ? CJPayOuterTypeAppPay : CJPayOuterTypeWebPay jumpBackURL:self.jumpBackUrlStr jumpBackResult:resultType complettion:nil];
}

#pragma mark - Private methods
- (void)p_checkValid {
    [CJPayPerformanceMonitor trackAPIStartWithAPIScene:CJPayPerformanceAPISceneOuterPay extra:@{}];
    [self p_createBaseTrackParams:self.schemaParams];
    @CJWeakify(self)
    [CJPayOuterPayUtil checkPaymentParamsValid:self.schemaParams
                             completion:^(CJPayDypayResultType resultType, NSString * _Nonnull errorMsg) {
        @CJStrongify(self)
        if (resultType == CJPayDypayResultTypeLowVersion) {
            [self p_alertUpgradeVersion];
        } else if (resultType != CJPayDypayResultTypeSuccess) {
            [self alertRequestErrorWithMsg:CJString(errorMsg)
                                 clickAction:^{
                @CJStrongify(self)
                [self closeCashierDeskAndJumpBackWithResult:resultType];
            }];
            [self didFinishParamsCheck:NO];
            return;
        }
        [self didFinishParamsCheck:YES];
    }];
}

- (void)p_setupUI {
    self.navigationBar.hidden = YES;
    self.view.backgroundColor = [UIColor cj_393b44ff];
    [self.view addSubview:self.tipLabel];
    [self.view addSubview:self.userInfoView];
    [self.userInfoView addSubview:self.userAvatarImageView];
    [self.userInfoView addSubview:self.userNicknameLabel];
    
    [self.view addSubview:self.singleLineUserInfoView];
    [self.singleLineUserInfoView addSubview:self.singleLineUserAvatarImageView];
    [self.singleLineUserInfoView addSubview:self.singleLineUserNicknameLabel];
    
    self.singleLineUserInfoView.alpha = 0;
    
    if ([CJPayRequestParam gAppInfoConfig].userNicknameBlock) {
        NSString *nickName = [CJPayRequestParam gAppInfoConfig].userNicknameBlock();
        if (Check_ValidString(nickName)) {
            self.userNicknameLabel.text = nickName;
            self.singleLineUserNicknameLabel.text = nickName;
        }
    }
    
    if ([CJPayRequestParam gAppInfoConfig].userPhoneNumberBlock) {
        NSString *phoneNumber = [CJPayRequestParam gAppInfoConfig].userPhoneNumberBlock();
        if (Check_ValidString(phoneNumber)) {
            self.userNicknameLabel.text = phoneNumber;
            self.singleLineUserNicknameLabel.text = phoneNumber;
        }
    }

    if ([CJPayRequestParam gAppInfoConfig].userAvatarBlock && [CJPayRequestParam gAppInfoConfig].userAvatarBlock()) {
        [self.userAvatarImageView cj_setImageWithURL:[CJPayRequestParam gAppInfoConfig].userAvatarBlock()];
        [self.singleLineUserAvatarImageView cj_setImageWithURL:[CJPayRequestParam gAppInfoConfig].userAvatarBlock()];
    }
    
    NSString *appID = [self.schemaParams cj_stringValueForKey:@"app_id"];
    if (appID && appID.length) {
        self.isFromApp = YES;
    } else {
        // 端外浏览器拉起
        self.isFromApp = NO;
    }
    
    CGFloat maginToBottom = -16 - [self halfVCContainerHeight];
    
    CJPayMasUpdate(self.navigationBar.titleLabel, {
        make.left.equalTo(self.navigationBar).offset(52);
        make.right.equalTo(self.navigationBar).offset(-52);
    })
    
    CJPayMasMaker(self.tipLabel, {
        make.left.equalTo(self.view).offset(15);
        make.right.equalTo(self.view).offset(-15);
        make.height.mas_equalTo(18);
        make.bottom.equalTo(self.view).offset(maginToBottom);
    });
        
    CJPayMasMaker(self.userInfoView, {
        make.top.equalTo(self.view).offset(88 + 50 + CJ_STATUSBAR_HEIGHT);
        make.left.equalTo(self.view.mas_left).offset(52);
        make.right.equalTo(self.view.mas_right).offset(-52);
    });
    
    CJPayMasMaker(self.userAvatarImageView, {
        make.top.equalTo(self.userInfoView);
        make.centerX.equalTo(self.userInfoView);
        make.width.mas_equalTo(72);
        make.height.mas_equalTo(72);
    });
    
    CJPayMasMaker(self.userNicknameLabel, {
        make.left.right.bottom.equalTo(self.userInfoView);
        make.top.equalTo(self.userAvatarImageView.mas_bottom).offset(8);
    });
    
    CJPayMasMaker(self.singleLineUserInfoView, {
        make.top.equalTo(self.view).offset(CJ_STATUSBAR_HEIGHT + 100 - 16);
        make.centerX.equalTo(self.view);
    });
    
    CJPayMasMaker(self.singleLineUserAvatarImageView, {
        make.top.left.bottom.equalTo(self.singleLineUserInfoView);
        make.height.width.mas_equalTo(32);
    });
    
    CJPayMasMaker(self.singleLineUserNicknameLabel, {
        make.centerY.equalTo(self.singleLineUserAvatarImageView);
        make.left.equalTo(self.singleLineUserAvatarImageView.mas_right).offset(12);
        make.right.equalTo(self.singleLineUserInfoView);
    });
    
    self.userInfoView.hidden = YES; // 刚开始不显示用户昵称和头像，等Loading结束后再展示
}

- (void)p_alertUpgradeVersion {
    @CJWeakify(self)
    [CJPayAlertUtil customDoubleAlertWithTitle:@"你的抖音版本过低，升级后才能使用该功能"
                                       content:@""
                                leftButtonDesc:@"取消"
                               rightButtonDesc:@"去升级"
                               leftActionBlock:^{
        @CJStrongify(self)
        [self closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeFailed];
    } rightActioBlock:^{
        [CJPayPrivacyMethodUtil applicationOpenUrl:[NSURL URLWithString:@"https://apps.apple.com/cn/app/%E6%8A%96%E9%9F%B3/id1142110895"]
                                        withPolicy:@"bpea-caijing_outer_goto_appstore"
                                   completionBlock:^(NSError * _Nullable error) {
            if (error) {
                CJPayLogError(@"error in bpea-caijing_outer_goto_appstore");
                return;
            }
            @CJStrongify(self)
            [self closeWithAnimated:YES];
        }];
    } useVC:self];
    
    NSMutableDictionary *trackParams = [NSMutableDictionary new];
    if (Check_ValidDictionary(self.baseTrackParams)) {
        [trackParams addEntriesFromDictionary:self.baseTrackParams];
        NSTimeInterval currentTimestamp = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
        NSTimeInterval startTimestamp = [self.baseTrackParams cj_doubleValueForKey:@"client_base_time"];
        if (startTimestamp > 100000) {
            [trackParams cj_setObject:@((int)(currentTimestamp-startTimestamp)) forKey:@"client_duration"];
        }
    }
    [trackParams cj_setObject:@"抖音版本过低" forKey:@"error_msg"];
    [CJTracker event:@"wallet_cashier_douyin_to_pay_error_pop" params:trackParams];
}

#pragma mark - Track event
- (void)p_createBaseTrackParams:(NSDictionary *)schemaParams {
    NSString *prepayId = [schemaParams cj_stringValueForKey:@"prepayid"];
    NSString *openMerchantId = [schemaParams cj_stringValueForKey:@"partnerid" defaultValue:@""];
    if (!Check_ValidString(openMerchantId)) {
        openMerchantId = [schemaParams cj_stringValueForKey:@"merchant_id" defaultValue:@""];
    }
    NSString *outerId = [schemaParams cj_stringValueForKey:@"app_id" defaultValue:@""];
    if (!Check_ValidString(outerId)) {
        outerId = [schemaParams cj_stringValueForKey:@"merchant_app_id" defaultValue:@""];
    }
    NSString *outerSource = [schemaParams cj_stringValueForKey:@"pay_source"];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval startTimestamp = [date timeIntervalSince1970] * 1000;
    if ([schemaParams cj_doubleValueForKey:@"client_base_time"]) {
        startTimestamp = [schemaParams cj_doubleValueForKey:@"client_base_time"];
    }
    
    NSDictionary *baseTrackParams = @{
        @"app_id" : CJString(outerId),
        @"merchant_id" : CJString(openMerchantId),
        @"caijing_source" : CJString(outerSource),
        @"is_chaselight" : @"1",
        @"prepay_id" : CJString(prepayId),
        @"client_base_time": @((int)startTimestamp),
    };
    self.baseTrackParams = baseTrackParams;
}

#pragma mark - CJPayAPIDelegate
- (void)callState:(BOOL)success fromScene:(CJPayScene)scene
{
    if (!success) {
        [self closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeUnknow];
    }
}

- (void)onResponse:(CJPayAPIBaseResponse *)response
{
    if (response.scene == CJPaySceneH5Pay) {
        [self closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeUnknow];
    }
}

#pragma mark - Setter & Getter
- (NSString *)jumpBackUrlStr {
    NSString *jumpBackSchema = [self.schemaParams cj_stringValueForKey:@"jump_back_schema"]; //app通过schema传，浏览器后端下发
    return Check_ValidString(jumpBackSchema) ? jumpBackSchema : CJString(self.returnURL);
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [UILabel new];
        _tipLabel.textColor = [[UIColor cj_999999ff] colorWithAlphaComponent:0.5];
        _tipLabel.font = [UIFont cj_fontOfSize:12];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _tipLabel;
}

- (UILabel *)userNicknameLabel {
    if (!_userNicknameLabel) {
        _userNicknameLabel = [UILabel new];
        _userNicknameLabel.textColor = [UIColor cj_ffffffWithAlpha:1.0];
        _userNicknameLabel.font = [UIFont cj_boldFontOfSize:14];
        _userNicknameLabel.numberOfLines = 1;
        _userNicknameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _userNicknameLabel;
}

- (UIImageView *)userAvatarImageView {
    if (!_userAvatarImageView) {
        _userAvatarImageView = [UIImageView new];
        _userAvatarImageView.alpha = 0.5;
        _userAvatarImageView.layer.cornerRadius = 36.f;
        _userAvatarImageView.clipsToBounds = YES;
    }
    return _userAvatarImageView;
}

- (UIView *)userInfoView {
    if (!_userInfoView) {
        _userInfoView = [UIView new];
        _userInfoView.backgroundColor = [UIColor clearColor];
        _userInfoView.alpha = 0.5;
    }
    return _userInfoView;
}

- (UILabel *)singleLineUserNicknameLabel {
    if (!_singleLineUserNicknameLabel) {
        _singleLineUserNicknameLabel = [UILabel new];
        _singleLineUserNicknameLabel.textColor = [UIColor cj_ffffffWithAlpha:1.0];
        _singleLineUserNicknameLabel.font = [UIFont cj_boldFontOfSize:14];
        _singleLineUserNicknameLabel.numberOfLines = 1;
        _singleLineUserNicknameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _singleLineUserNicknameLabel;
}

- (UIImageView *)singleLineUserAvatarImageView {
    if (!_singleLineUserAvatarImageView) {
        _singleLineUserAvatarImageView = [UIImageView new];
        _singleLineUserAvatarImageView.alpha = 0.5;
        _singleLineUserAvatarImageView.layer.cornerRadius = 16.f;
        _singleLineUserAvatarImageView.clipsToBounds = YES;
    }
    return _singleLineUserAvatarImageView;
}

- (UIView *)singleLineUserInfoView {
    if (!_singleLineUserInfoView) {
        _singleLineUserInfoView = [UIView new];
        _singleLineUserInfoView.backgroundColor = [UIColor clearColor];
        _singleLineUserInfoView.alpha = 0.5;
    }
    return _singleLineUserInfoView;
}

- (CGFloat)halfVCContainerHeight {
    return CJ_HALF_SCREEN_HEIGHT_LOW;
}

@end
