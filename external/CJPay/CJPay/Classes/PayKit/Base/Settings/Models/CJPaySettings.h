//
//  CJPaySettings.h
//  CJPay
//
//  Created by liyu on 2020/3/17.
//

#import <JSONModel/JSONModel.h>
#import "CJPayForceHttpsModel.h"
#import "CJPayWebviewMonitorConfigModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayDegradeModel;

@protocol CJPayThemeStyle;
@protocol CJPayDegradeModel;

@interface CJPayBindCardUISettingsModel : JSONModel

@property (nonatomic, assign) BOOL isShowIDProfileCard;
@property (nonatomic, assign) BOOL updateMerchantId;
@property (nonatomic, assign) NSInteger userInputCacheDuration;

@end

@interface CJPayBrandPromoteModel : JSONModel

@property (nonatomic, assign) BOOL showNewLoading;
@property (nonatomic, assign) BOOL showNewAlertType;
@property (nonatomic, copy) NSString *halfInputPasswordTitle;
@property (nonatomic, copy) NSString *fullVerifyPasswordTitle;
@property (nonatomic, copy) NSString *fullSetPasswordTitle;
@property (nonatomic, copy) NSString *fullSetPasswordTitleAgain;
@property (nonatomic, copy) NSString *cashierTitle;
@property (nonatomic, copy) NSString *addCardTitle;
@property (nonatomic, copy) NSString *addCardH1Title;
@property (nonatomic, copy) NSString *oneKeyQuickCashierTitle;
@property (nonatomic, copy) NSArray<NSString *> *douyinLoadingUrlList;

@end

@interface CJPayABSettingsModel : JSONModel

@property (nonatomic, assign) BOOL isHiddenDouyinLogo;
@property (nonatomic, assign) BOOL showAccountInsuracne;
@property (nonatomic, copy) NSString *darkAccountInsuranceUrl;
@property (nonatomic, copy) NSString *lightAccountInsuranceUrl;
@property (nonatomic, copy) NSString *keyboardDenoiseIconUrl;
@property (nonatomic, copy) NSString *amountKeyboardInsuranceUrl;
@property (nonatomic, copy) NSString *amountKeyboardDarkInsuranceUrl;

@property (nonatomic, strong) CJPayBrandPromoteModel *brandPromoteModel;

@end


@interface CJPayFalconDefaultConfigModel : JSONModel

@property (nonatomic, assign) BOOL enableDefaultConfig;
@property (nonatomic, copy) NSArray<NSString *> *prefixList;
@property (nonatomic, copy) NSArray<NSString *> *channelList;

@end

@interface CJPayFalconHtmlConfigModel : JSONModel

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *file;

@end

@protocol CJPayFalconHtmlConfigModel;
@interface CJPayFalconCustomConfigModel : JSONModel

@property (nonatomic, assign) BOOL enableCustomConfig;
@property (nonatomic, assign) BOOL interceptHtml;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSArray<NSString *> *hostList;
@property (nonatomic, copy) NSString *assetPath;
@property (nonatomic, copy) NSArray<CJPayFalconHtmlConfigModel> *htmlFileList;

@end


@protocol CJPayFalconDefaultConfigModel;
@protocol CJPayFalconCustomConfigModel;
@interface CJPayFalconSettingsModel : JSONModel

@property (nonatomic, assign) BOOL enableIntercept;
@property (nonatomic, copy) NSArray<CJPayFalconDefaultConfigModel> *falconConfigList;
@property (nonatomic, copy) NSArray<CJPayFalconCustomConfigModel> *customConfigList;

@end

@interface CJPayGurdSettingsModel : JSONModel

@property (nonatomic, assign) BOOL offlineRollback;
@property (nonatomic, assign) BOOL isMergeRequest;
@property (nonatomic, strong) CJPayFalconSettingsModel *falconSettings;

@end

@interface CJPayGurdImgModel : JSONModel

@property (nonatomic, assign) BOOL enableGurdImg;
@property (nonatomic, copy) NSString *cdnUrl;
@property (nonatomic, copy) NSArray<NSString *> *iosImgChannelList;

@end

@interface CJPayDataSecurity : JSONModel

@property (nonatomic, assign) BOOL enableDataSecurity;
@property (nonatomic, assign) BOOL blurType;

@end

@interface CJPayLoadingConfig : JSONModel

@property (nonatomic, assign) BOOL enableHalfLoadingUseWindow;
@property (nonatomic, assign) NSInteger halfLoadingTimeOut;
@property (nonatomic, assign) NSInteger superPayLoadingTimeOut;
@property (nonatomic, assign) NSInteger superPayLoadingQueryInterval;
@property (nonatomic, assign) NSInteger superPayLoadingStayTime;
@property (nonatomic, assign) BOOL isEcommerceDouyinLoadingAutoClose;
@property (nonatomic, assign) NSInteger loadingTimeOut;
@property (nonatomic, copy) NSString *superPayLoadingFailTitle;
@property (nonatomic, copy) NSString *superPayLoadingFailSubTitle;

@end

@interface CJPaySignPayConfig : JSONModel

@property (nonatomic, assign) BOOL useNativeSignLogin;
@property (nonatomic, assign) BOOL useNativeSignAndPay;

@end

@interface CJPayAccountInsuranceEntrance : JSONModel

@property (nonatomic, assign) BOOL showInsuranceEntrance;

@end

@interface CJPayFastPayModel : JSONModel

@property (nonatomic, assign) NSInteger timeOut;
@property (nonatomic, assign) NSInteger queryMaxTimes;

- (NSInteger)maxQueryTimes;

@end

@interface CJPayWebViewCommonConfigModel : JSONModel

@property (nonatomic, copy) NSArray<NSString *> *intergratedHostReplaceBlockList;
@property (nonatomic, assign) BOOL useIESAuthManager;
@property (nonatomic, assign) BOOL offlineUseSchemeHandler;
@property (nonatomic, copy) NSArray<NSString *> *offlineExcludeUrlList;
@property (nonatomic, assign) NSInteger showErrorViewTimeout;
@property (nonatomic, copy) NSArray<NSString *> *showErrorViewDomainList;


@end

@interface CJPayIAPConfigModel : JSONModel

@property (nonatomic, assign) BOOL useNewIAP;
@property (nonatomic, assign) BOOL enableSK2;
@property (nonatomic, assign) BOOL enableSK1Observer;
@property (nonatomic, assign) BOOL isNeedPendingReturnFail;
@property (nonatomic, copy) NSArray<NSString *> *loadingDescription;
@property (nonatomic, copy) NSArray *loadingDescriptionTime;

@end

@interface CJPayAlogReportConfigModel : JSONModel

@property (nonatomic, assign) BOOL reportEnable;
@property (nonatomic, assign) NSInteger reportTimeInterval;
@property (nonatomic, assign) NSInteger reportEnableInterval;
@property (nonatomic, copy) NSArray<NSString *> *eventWhiteList;

@end

@interface CJPayRDOptimizationConfig : JSONModel

@property (nonatomic, assign) BOOL isPopupVCUseCoordinatorPop;
@property (nonatomic, assign) BOOL isAddLoadingViewInTopHalfPage;
@property (nonatomic, assign) BOOL isTransitionUseSnapshot;
@property (nonatomic, assign) BOOL isDisableMonitorRequestBizResult; // 是否禁止上报网络请求业务结果监控

@end

@interface CJPayBindCardUIConfig : JSONModel

@property (nonatomic, assign) BOOL showIDOCR;

@end

// 独立绑卡聚合商户信息
@interface CJPayJHInformationConfig : JSONModel

@property (nonatomic, copy) NSString *jhMerchantId;
@property (nonatomic, copy) NSString *jhAppId;
@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) NSString *teaSourceNtv;
@property (nonatomic, copy) NSString *teaSourceLynx;

@end

//新样式Loading具体配置
@interface CJPayStyleLoadingConfig : JSONModel

@property (nonatomic, copy) NSString *dialogPreGif;
@property (nonatomic, copy) NSString *dialogRepeatGif;
@property (nonatomic, copy) NSString *dialogCompleteSuccessGif;
@property (nonatomic, copy) NSString *panelPreGif;
@property (nonatomic, copy) NSString *panelRepeatGif;
@property (nonatomic, copy) NSString *panelCompleteSuccessGif;

@end

//新样式Loading图片信息 cycle圆圈循环样式 breathe盾牌呼吸样式
@interface CJPaySecurityLoadingConfig : JSONModel

@property (nonatomic, strong) CJPayStyleLoadingConfig *cycleStyleLoadingConfig;
@property (nonatomic, strong) CJPayStyleLoadingConfig *breatheStyleLoadingConfig;

@end

//H5页面替换成lynx页面
@interface CJPayMigrateH5PageToLynx : JSONModel

@property (nonatomic, copy) NSString *forgetpassSchema;//忘记密码的lynx链接

@end

@interface CJPayKeepDialogStandard : JSONModel

@property (nonatomic, copy) NSString *scheme; // 获取lynx挽留弹窗的schema
@property (nonatomic, assign) NSInteger fallbackWaitTimeMillis; // 获取lynx挽留弹窗最高加载时长 单位为ms

@end

@interface CJPayLynxSchemaConfig : JSONModel

@property (nonatomic, copy) NSString *myBankCard;
@property (nonatomic, copy) NSString *retainPopup;
@property (nonatomic, strong) CJPayKeepDialogStandard *keepDialogStandardNew;
@property (nonatomic, copy) NSString *loginInfo;
@property (nonatomic, copy) NSString *payUpgradeSchema;

@end

@interface CJPayContainerConfig : JSONModel

@property (nonatomic, assign) BOOL enable;
@property (nonatomic, assign) BOOL disableAlog;
@property (nonatomic, assign) NSInteger colorDiff;
@property (nonatomic, assign) BOOL disableBlankDetect;
@property (nonatomic, copy) NSArray<NSString *> *urlBlockList;
@property (nonatomic, assign) BOOL enableHybridkitUA;
@property (nonatomic, assign) BOOL cjwebEnable;
@property (nonatomic, copy) NSArray<NSString *> *cjwebUrlBlockList;
@property (nonatomic, copy) NSArray<NSString *> *cjwebUrlAllowList;

@end

@interface CJPayUploadMediaConfig : JSONModel

@property (nonatomic, assign) NSInteger defaultMaxSize; // JSB接口upload_media的最大图片尺寸
@property (nonatomic, assign) NSInteger defaultMaxResolution; // JSB接口upload_media的最大图片分辨率

@end

@interface CJPayNativeBindCardConfig : JSONModel

@property (nonatomic, assign) BOOL enableNativeBindCard;

@end


@interface CJPayLynxSchemaParamsRule : JSONModel

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSArray<NSString *> *keys;

@end

@protocol CJPayLynxSchemaParamsRule;
@interface CJPayLynxSchemaParamsConfig : JSONModel

@property (nonatomic, assign) BOOL enable;
@property (nonatomic, assign) CGFloat paramsLimit;
@property (nonatomic, copy) NSArray<CJPayLynxSchemaParamsRule> *rules;

@end

@class CJPayHostModel;
@interface CJPaySettings : JSONModel

@property (nonatomic, copy) NSArray<CJPayDegradeModel> *degradeModels;
@property (nonatomic, copy) NSDictionary *themeModelDic;
@property (nonatomic, strong) CJPayForceHttpsModel *forceHttpsModel;
@property (nonatomic, strong) CJPayWebviewMonitorConfigModel *webviewMonitorConfigModel;
@property (nonatomic, copy) NSArray<NSString *> *secDomains;
@property (nonatomic, copy) NSArray<NSString *> *loadingPath;
@property (nonatomic, copy) NSDictionary *webviewPrefetchConfig;
@property (nonatomic, strong) CJPayHostModel *cjpayNewCustomHost;//追光
@property (nonatomic, copy) NSString * cjpayCustomHost;//聚合
@property (nonatomic, strong) CJPayABSettingsModel *abSettingsModel;
@property (nonatomic, copy) NSDictionary *abSettingsDic;
@property (nonatomic, copy) NSDictionary *libraABSettingsDic;
@property (nonatomic, strong) CJPayGurdSettingsModel *gurdFalconModel;//H5 Gecko & Falcon配置
@property (nonatomic, strong) CJPayGurdImgModel *gurdImgModel;//IMG Gecko配置
@property (nonatomic, strong) CJPayFastPayModel *fastPayModel; //极速支付超时时间
@property (nonatomic, strong) CJPayAccountInsuranceEntrance *accountInsuranceEntrance; //安全险入口显示
@property (nonatomic, strong) CJPayDataSecurity *enableDataSecurity;
@property (nonatomic, copy) NSArray *bankParamsArray; //一键绑卡aid&appParams
@property (nonatomic, assign) BOOL performanceMonitorIsOpened;
@property (nonatomic, assign) BOOL isHitEventUploadSampled;
@property (nonatomic, strong) CJPayWebViewCommonConfigModel *webviewCommonConfigModel;
@property (nonatomic, strong) CJPayLoadingConfig *loadingConfig;
@property (nonatomic, strong) CJPaySignPayConfig *signPayConfig;
@property (nonatomic, copy) NSArray *aid2PlatformIdMap; //CJPayUserAuthBindRequest接口中aid&platformId的map
@property (nonatomic, strong) CJPayIAPConfigModel *iapConfigModel;
@property (nonatomic, strong) CJPayJHInformationConfig *jhConfig;
@property (nonatomic, copy) NSString *engimaVersion;
@property (nonatomic, copy) NSString *oneKeyAssemble;
@property (nonatomic, assign) BOOL disableViolentClickPrevent; // 禁用防暴击方案
@property (nonatomic, strong) CJPayRDOptimizationConfig *rdOptimizationConfig;
@property (nonatomic, strong) CJPayBindCardUIConfig *bindCardUIConfig;
@property (nonatomic, copy) NSString *topVCV2;
@property (nonatomic, strong) CJPayBindCardUISettingsModel *bindCardUISettings;
@property (nonatomic, copy) NSDictionary *rechargeWithdrawConfig;
@property (nonatomic, strong) CJPaySecurityLoadingConfig *securityLoadingConfig;
@property (nonatomic, copy) NSString *bindcardLynxUrl;
@property (nonatomic, strong) CJPayMigrateH5PageToLynx *migrateH5PageToLynx;
@property (nonatomic, assign) BOOL isVIP;
@property (nonatomic, strong) CJPayAlogReportConfigModel *alogReportConfigModel;
@property (nonatomic, strong) CJPayLynxSchemaConfig *lynxSchemaConfig;
@property (nonatomic, copy) NSString *redpackBackgroundURL;
@property (nonatomic, strong) CJPayContainerConfig *containerConfig;
@property (nonatomic, strong) CJPayUploadMediaConfig *uploadMediaConfig;
@property (nonatomic, copy) NSDictionary *dataDict;
@property (nonatomic, strong) CJPayNativeBindCardConfig *nativeBindCardConfig;
@property (nonatomic, strong) CJPayLynxSchemaParamsConfig *lynxSchemaParamsConfig;

- (NSArray<NSString *> *)getThemedH5PathList;

@end

NS_ASSUME_NONNULL_END
