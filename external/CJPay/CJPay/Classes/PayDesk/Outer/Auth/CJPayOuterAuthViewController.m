//
//  CJPayOuterAuthViewController.m
//  CJPay
//
//  Created by 尚怀军 on 2020/9/24.
//

#import "CJPayOuterAuthViewController.h"
#import "CJPayHomePageViewController.h"
#import "CJPayRequestParam.h"
#import "CJPayCreateOrderByTokenRequest.h"
#import "CJPayAlertUtil.h"
#import "CJPayProtocolManager.h"
#import "CJPayH5DeskModule.h"
#import "CJPaySettings.h"
#import "CJPaySettingsManager.h"
#import "CJPayDegradeModel.h"
#import "CJPayCommonTrackUtil.h"
#import "CJPayOPHomePageViewController.h"
#import "UIImageView+CJPay.h"
#import "CJPayPrivacyMethodUtil.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayBytePayHomePageViewController.h"
#import "CJPayOuterPayUtil.h"
#import "CJPayAlertUtil.h"
#import "CJPayQueryBindAuthorizeInfoRequest.h"
#import "CJPayQueryBindAuthorizeInfoResponse.h"
#import "CJPayOuterBizAuthViewController.h"

@interface CJPayOuterAuthViewController () <CJPayAPIDelegate>

@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UILabel *userNicknameLabel; // 用户昵称
@property (nonatomic, strong) UIImageView *userAvatarImageView; // 用户头像
@property (nonatomic, copy) NSString *returnURL;
@property (nonatomic, strong) UIView *userInfoView; //承载用户昵称和用户头像
@property (nonatomic, strong) CJPayHomePageViewController *homePageVC;
@property (nonatomic, strong) CJPayCreateOrderResponse *orderResponse; // 埋点用
@property (nonatomic, assign) BOOL isFromApp; // 判断是从 App 还是 safari 发起的支付
@property (nonatomic, assign) BOOL isColdLaunch; // 是否为冷启动进入支付
@property (nonatomic, assign) double lastTimestamp; // 上一次上报 event 的时间戳

@end

@implementation CJPayOuterAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self p_setupUI];
    [self p_openBindVC];
}

- (void)p_setupUI {
    self.navigationBar.hidden = YES;
    self.view.backgroundColor = [UIColor cj_393b44ff];
    [self.view addSubview:self.tipLabel];
    [self.view addSubview:self.userInfoView];
    [self.userInfoView addSubview:self.userAvatarImageView];
    [self.userInfoView addSubview:self.userNicknameLabel];
    
    if ([CJPayRequestParam gAppInfoConfig].userNicknameBlock) {
        NSString *nickName = [CJPayRequestParam gAppInfoConfig].userNicknameBlock();
        if (Check_ValidString(nickName)) {
            self.userNicknameLabel.text = nickName;
        }
    }
    
    if ([CJPayRequestParam gAppInfoConfig].userPhoneNumberBlock) {
        NSString *phoneNumber = [CJPayRequestParam gAppInfoConfig].userPhoneNumberBlock();
        if (Check_ValidString(phoneNumber)) {
            self.userNicknameLabel.text = phoneNumber;
        }
    }

    if ([CJPayRequestParam gAppInfoConfig].userAvatarBlock && [CJPayRequestParam gAppInfoConfig].userAvatarBlock()) {
        [self.userAvatarImageView cj_setImageWithURL:[CJPayRequestParam gAppInfoConfig].userAvatarBlock()];
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
        make.center.equalTo(self.view);
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
    
}

- (void)p_openBindVC {
    __block CJPayDypayResultType checkResult = CJPayDypayResultTypeSuccess;
    [CJPayOuterPayUtil checkAuthParamsValid:self.schemaParams completion:^(CJPayDypayResultType resultType, NSString * _Nonnull errorMsg) {
        checkResult = resultType;
        if (resultType == CJPayDypayResultTypeLowVersion) {
            [self p_alertUpgradeVersion];
        } else if (resultType != CJPayDypayResultTypeSuccess) {
            @CJWeakify(self)
            [self p_alertRequestErrorWithMsg:CJString(errorMsg)
                                 clickAction:^{
                @CJStrongify(self)
                [self p_closeCashierDeskAndJumpBackWithResult:resultType];
            }];
        }
    }];
    
    if (checkResult != CJPayDypayResultTypeSuccess) {
        return;
    }
    
    NSString *bindContent = [self.schemaParams cj_stringValueForKey:@"bind_content"];
    // request
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinOpenDeskLoading vc:self];
    @CJWeakify(self)
    [CJPayQueryBindAuthorizeInfoRequest startWithAppId:[CJPayRequestParam gAppInfoConfig].appId
                                              bizParam:@{
        @"bind_content" : CJString(bindContent)
        }
                                            completion:^(NSError * _Nonnull error, CJPayQueryBindAuthorizeInfoResponse * _Nonnull response) {
        [[CJPayLoadingManager defaultService] stopLoading];
        if (![response isSuccess]) {
            @CJStrongify(self)
            NSString *alertText = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
            [self p_alertRequestErrorWithMsg:alertText clickAction:^{
                @CJStrongify(self)
                [self p_closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeFailed];
            }];
            return;
        }
        
        CJPayOuterBizAuthViewController *authVC = [[CJPayOuterBizAuthViewController alloc] initWithResponse:response];
        authVC.bindContent = bindContent;
        authVC.confirmBlock = ^{
            @CJStrongify(self)
            [self p_closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeSuccess];
        };
        authVC.cancelBlock = ^(CJPayDypayResultType type) {
            @CJStrongify(self);
            [self p_closeCashierDeskAndJumpBackWithResult:type];
        };
        
        authVC.animationType = HalfVCEntranceTypeFromBottom;
        //加个延时，在loading做完消失动画后再推出confirmVC
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @CJStrongify(self)
            [authVC presentWithNavigationControllerFrom:self useMask:NO completion:nil];
            // 推出首页时触发背景的用户信息动画
            [self p_startBackgroundAnimation];
        });
    }];
}

- (void)p_closeCashierDeskAndJumpBackWithResult:(CJPayDypayResultType)resultType {
    [CJPayOuterPayUtil closeCashierDeskVC:self signType:self.isFromApp ? CJPayOuterTypeAppPay : CJPayOuterTypeWebPay jumpBackURL:[self p_getJumpBackUrlStr] jumpBackResult:resultType complettion:nil];
}

- (void)p_alertUpgradeVersion {
    @CJWeakify(self)
    [CJPayAlertUtil customDoubleAlertWithTitle:@"你的抖音版本过低，升级后才能使用该功能"
                                       content:@""
                                leftButtonDesc:@"取消"
                               rightButtonDesc:@"去升级"
                               leftActionBlock:^{
        @CJStrongify(self)
        [self p_closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeFailed];
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
}

- (void)p_alertRequestErrorWithMsg:(NSString *)alertText
                       clickAction:(void(^)(void))clickAction {
    [CJPayAlertUtil customSingleAlertWithTitle:alertText content:@"" buttonDesc:CJPayLocalizedStr(@"知道了") actionBlock:^{
        CJ_CALL_BLOCK(clickAction);
    } useVC:self];
}

- (NSString *)p_getJumpBackUrlStr {
    NSString *jumpBackSchema = [self.schemaParams cj_stringValueForKey:@"jump_back_schema"]; //app通过schema传，浏览器后端下发
    return Check_ValidString(jumpBackSchema) ? jumpBackSchema : CJString(self.returnURL);
}

- (NSDictionary *)p_mergeCommonParamsWith:(NSDictionary *)dic
                                 response:(CJPayCreateOrderResponse *)response {
    NSMutableDictionary *totalDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    NSDictionary *commonParams = [CJPayCommonTrackUtil getCashDeskCommonParamsWithResponse:response
                                                                         defaultPayChannel:response.payInfo.defaultPayChannel];
    [totalDic addEntriesFromDictionary:commonParams];
    [totalDic addEntriesFromDictionary:@{@"douyin_version": CJString([CJPayRequestParam appVersion])}];
    return totalDic;
}

- (void)p_startBackgroundAnimation {

    self.userInfoView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    self.userInfoView.alpha = 0;
    CGFloat transitionHeight = self.userInfoView.cj_centerY - CJ_STATUSBAR_HEIGHT - 88 - 50;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        
        CGAffineTransform scaleTrans = CGAffineTransformMakeScale(1, 1);
        CGAffineTransform translationTrans = CGAffineTransformMakeTranslation(0, -transitionHeight);
        self.userInfoView.transform = CGAffineTransformConcat(scaleTrans, translationTrans);
        self.userInfoView.alpha = 0.5;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - CJPayAPIDelegate
- (void)callState:(BOOL)success fromScene:(CJPayScene)scene {
    if (!success) {
        [self p_closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeUnknow];
    }
}

- (void)onResponse:(CJPayAPIBaseResponse *)response {
    if ([self.apiDelegate respondsToSelector:@selector(onResponse:)]) {
        [self.apiDelegate onResponse:response];
    }
    
    if (response.scene == CJPaySceneH5Pay) {
        [self p_closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeUnknow];
    }
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
        [_userAvatarImageView cj_setImage:@"cj_default_user_avatar_icon"];
        _userAvatarImageView.clipsToBounds = YES;
    }
    return _userAvatarImageView;
}

- (UIView *)userInfoView {
    if (!_userInfoView) {
        _userInfoView = [UIView new];
        _userInfoView.backgroundColor = [UIColor clearColor];
        _userInfoView.alpha = 0;
    }
    return _userInfoView;
}

- (CGFloat)halfVCContainerHeight {
    return CJ_HALF_SCREEN_HEIGHT_LOW;
}

@end
