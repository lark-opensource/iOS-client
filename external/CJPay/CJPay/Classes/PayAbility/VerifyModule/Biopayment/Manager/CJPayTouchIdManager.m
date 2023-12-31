//
//  CJPayTouchIdManager.m
//  CJPay
//
//  Created by 王新华 on 2019/1/6.
//

#import "CJPayTouchIdManager.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "CJPayUIMacro.h"
#import <SAMKeychain/SAMKeychain.h>

static NSString *const CJPayTouchIdDataService = @"CJPayTouchIdDataService";
static NSString *CJPayCurrentTouchIdIdentify = @"CJPay";
static NSString *const CJPayCurrentTouchIdIdentify_PERFIX = @"TOUCH_ID@";

@interface CJPayTouchIDEvaluatePolicyData : NSObject

@property (nonatomic, assign) BOOL isLockOut;
@property (nonatomic, assign) BOOL isBiometryNotAvailable;
@property (nonatomic, assign) BOOL isTouchIDNotEnrolled;
@property (nonatomic, assign) CJPayBioPaymentType currentSupportBiopaymentType;
@property (nonatomic, strong, nullable) NSData *evaluatedPolicyDomainState;

@end


@implementation CJPayTouchIDEvaluatePolicyData

@end


@interface CJPayTouchIdManager ()

@property (nonatomic, strong) CJPayTouchIDEvaluatePolicyData *evaluatePolicyData;
@property (nonatomic, assign) BOOL isEvaluateDataValid;
@property (nonatomic, assign) CJPayBioPaymentType currentSupportBiopaymentType;

+ (CJPayBioPaymentType)p_getPaymentTypeAfterIOS11WithError:(NSError *)error ctx:(LAContext *)ctx API_AVAILABLE(ios(11.0));

@end


@implementation CJPayTouchIdManager

+ (CJPayBioPaymentType)currentSupportBiopaymentType {
    return self.p_evaluatePolicyData.currentSupportBiopaymentType;
}

// evaluatePolicy出错的情况下通过具体error判断支持哪种验证方式
+ (CJPayBioPaymentType)p_getSupportPaymentTypeWithError:(NSError *)error
                                                  ctx:(LAContext *)ctx {
    if (@available(iOS 11.0.1, *)) {
        return [self p_getPaymentTypeAfterIOS11WithError:error ctx:ctx];
    } else {
        return [self p_getPaymentTypeBeforeIOS11WithError:error ctx:ctx];
    }
}

+ (CJPayBioPaymentType)p_getPaymentTypeBeforeIOS11WithError:(NSError *)error
                                                    ctx:(LAContext *)ctx {
    switch (error.code) {
        case LAErrorTouchIDNotEnrolled:
        case LAErrorTouchIDLockout: {
            return CJPayBioPaymentTypeFinger;
        }
        case LAErrorPasscodeNotSet: {
            return CJPayBioPaymentTypeNone;
        }
        default: {
            return CJPayBioPaymentTypeNone;
        }
    }
}

+ (CJPayBioPaymentType)p_getPaymentTypeAfterIOS11WithError:(NSError *)error
                                                     ctx:(LAContext *)ctx {
    switch (error.code) {
        case LAErrorBiometryNotEnrolled:
        case LAErrorBiometryLockout: {
            if (ctx.biometryType == LABiometryTypeFaceID || [self p_isIphoneXR]) {
                // 如果已经是faceID了  则肯定不支持touchID 了
                return CJPayBioPaymentTypeFace;
            } else {
                return CJPayBioPaymentTypeFinger;
            }
        }
        case LAErrorBiometryNotAvailable: {
            if (ctx.biometryType == LABiometryTypeFaceID) {
                return CJPayBioPaymentTypeFace;
            }
            return CJPayBioPaymentTypeNone;
        }
        case LAErrorPasscodeNotSet: {
            return CJPayBioPaymentTypeNone;
        }
        default: {
            return CJPayBioPaymentTypeNone;
        }
    }
}

+ (BOOL)p_isIphoneXR {
    if (@available(iOS 11.0, *)) {
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        CGFloat maxLength = screenWidth > screenHeight ? screenWidth : screenHeight;
        
        if (maxLength == 812.0f || maxLength == 896.0f) {
            return YES;
        }
    }
    return NO;
}

+ (instancetype)p_sharedInstance {
    static CJPayTouchIdManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CJPayTouchIdManager alloc] init];
    });
    return instance;
}

+ (CJPayTouchIDEvaluatePolicyData *)p_evaluatePolicyData {
    return [CJPayTouchIdManager p_sharedInstance].p_theEvaluatePolicyData;
}


#pragma mark - open
//设置当前touchId的身份 切换身份的时候需要调用此方法
+ (void)setCurrentTouchIdDataIdentity:(NSString *)identity {
    CJPayCurrentTouchIdIdentify = identity;
}

+ (NSString*)currentTouchIdDataIdentity {
    return CJPayCurrentTouchIdIdentify;
}

+ (BOOL)touchIdInfoDidChange {
    NSData *data = self.p_evaluatePolicyData.evaluatedPolicyDomainState;
    if (!data && self.p_evaluatePolicyData.isLockOut) {
        //输入次数过多被锁定，此时指纹并没有变更
        return NO;
    }
    
    NSData *oldData = [self p_currentIdentityTouchIdData];
    
    if (oldData == nil) {
        //应用内该账户未设置过指纹
        return NO;
    } else if ([oldData isEqual:data]) {
        //没有变化
        return NO;
    } else {
        //指纹信息发生变化
        return YES;
    }
}

+ (void)showTouchIdWithLocalizedReason:(NSString *)localizedReason
                        falldBackTitle:(NSString *)falllBackTitle
                         fallBackBlock:(TouchIdFallBackBlock)fallBackBlock
                           resultBlock:(TouchIdResultBlock)resultBlock {
    [self showTouchIdWithLocalizedReason:localizedReason
                             cancelTitle:nil
                          falldBackTitle:falllBackTitle
                           fallBackBlock:fallBackBlock
                             resultBlock:resultBlock];
    
}

+ (void)showTouchIdWithLocalizedReason:(NSString *)localizedReason
                           cancelTitle:(nullable NSString *)cancelTitle
                        falldBackTitle:(NSString *)falllBackTitle
                         fallBackBlock:(TouchIdFallBackBlock)fallBackBlock
                           resultBlock:(TouchIdResultBlock)resultBlock {
    LAContext *context = [[LAContext alloc] init];
    context.localizedFallbackTitle = falllBackTitle;
    
    if (Check_ValidString(cancelTitle)) {
        if (@available(iOS 10.0, *)) {
            context.localizedCancelTitle = cancelTitle;
        }
    }
    
    //错误对象
    NSError* error = nil;
    //首先使用canEvaluatePolicy 判断设备支持状态
    BOOL canEvaluate = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    if (canEvaluate || [CJPayTouchIdManager isErrorBiometryLockout]) {
        // 这个方法才会请求授权
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                localizedReason:localizedReason
                          reply:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    // 指纹或面容验证成功
                    CJ_CALL_BLOCK(resultBlock, YES, YES, [[NSError alloc] initWithDomain:@"100" code:100 userInfo:@{NSLocalizedDescriptionKey : @"成功"}], LAPolicyDeviceOwnerAuthenticationWithBiometrics);
                } else {
                    [[CJPayTouchIdManager p_sharedInstance] p_setEvaluatePolicyDataStateWithEerror:error];
                    // 指纹或面容验证失败
                    if (@available(iOS 11.0, *)) {
                        if (error.code == LAErrorUserFallback) {
                            // 用户点击输入密码按钮
                            if (fallBackBlock) {
                                fallBackBlock();
                                return ;
                            }
                        } else if (error.code == LAErrorBiometryNotEnrolled) {
                            // 其他验证错误抛到外部处理
                            CJ_CALL_BLOCK(resultBlock, YES, NO, error, LAPolicyDeviceOwnerAuthenticationWithBiometrics);
                        } else if (error.code == LAErrorBiometryLockout) {
                            // 其他验证错误抛到外部处理
                            CJ_CALL_BLOCK(resultBlock, YES, NO, error, LAPolicyDeviceOwnerAuthenticationWithBiometrics);
                        } else {
                            // 其他验证错误抛到外部处理
                            CJ_CALL_BLOCK(resultBlock, YES, NO, error, LAPolicyDeviceOwnerAuthenticationWithBiometrics);
                        }
                    } else if (@available(iOS 9.0, *)) {
                        if (error.code == LAErrorUserFallback) {
                            // 用户点击输入密码按钮
                            if (fallBackBlock) {
                                fallBackBlock();
                                return ;
                            }
                        } else if (error.code == kLAErrorTouchIDNotEnrolled) {
                            // 其他验证错误抛到外部处理
                            CJ_CALL_BLOCK(resultBlock, YES, NO, error, LAPolicyDeviceOwnerAuthenticationWithBiometrics);
                        } else if (error.code == kLAErrorTouchIDLockout) {
                            // 其他验证错误抛到外部处理
                            CJ_CALL_BLOCK(resultBlock, YES, NO, error, LAPolicyDeviceOwnerAuthenticationWithBiometrics);
                        } else {
                            // 其他验证错误抛到外部处理
                            CJ_CALL_BLOCK(resultBlock, YES, NO, error, LAPolicyDeviceOwnerAuthenticationWithBiometrics);
                        }
                    } else {
                        // Fallback on earlier versions
                    }
                }
            });
        }];
    } else {
        [[CJPayTouchIdManager p_sharedInstance] p_setEvaluatePolicyDataStateWithEerror:error];
        // 其他验证错误抛到外部处理
        CJ_CALL_BLOCK(resultBlock, NO, NO, error, kLAPolicyDeviceOwnerAuthenticationWithBiometrics);
    }
}

#pragma mark - currentTouchIdData

+ (NSString*)p_accountForKeychainWithIdentify {
    if ([self currentTouchIdDataIdentity]) {
        return [CJPayCurrentTouchIdIdentify_PERFIX stringByAppendingString:[self currentTouchIdDataIdentity]];
    } else {
        return nil;
    }
}

+ (nullable NSData*)currentTouchIdDataForCompare {
    return self.p_evaluatePolicyData.evaluatedPolicyDomainState;
}

+ (nullable NSData*)currentOriTouchIdData {
    return self.p_evaluatePolicyData.evaluatedPolicyDomainState;
}

#pragma mark - identityTouchData

+ (nullable NSData*)p_currentIdentityTouchIdData {
    if ([self p_accountForKeychainWithIdentify]) {
        return [SAMKeychain passwordDataForService:CJPayTouchIdDataService account:[self p_accountForKeychainWithIdentify]];
    } else {
        return nil;
    }
}

+ (BOOL)isTouchIDNotEnrolled {
    return self.p_evaluatePolicyData.isTouchIDNotEnrolled;
}

+ (BOOL)isBiometryNotAvailable {
#if (TARGET_IPHONE_SIMULATOR)
    return NO;
#else
    return self.p_evaluatePolicyData.isBiometryNotAvailable;
#endif
}

#pragma mark -

+ (BOOL)isErrorBiometryLockout {
    return self.p_evaluatePolicyData.isLockOut;
}

+ (NSString *)currentBioType {
    static NSString *bioType = @"";  //缓存bioType，这个参数不会变，所以使用静态变量存储
    
    if (bioType && bioType.length > 0) {
        return bioType;
    }
    
    switch ([CJPayTouchIdManager currentSupportBiopaymentType]) {
        case CJPayBioPaymentTypeFace:
            bioType = @"2";
            break;
        case CJPayBioPaymentTypeFinger:
            bioType = @"1";
            break;
        default:
            bioType = @"0";
            break;
    }
    
    return bioType;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            self.isEvaluateDataValid = NO;
        }];
    }
    return self;
}

- (CJPayTouchIDEvaluatePolicyData *)p_theEvaluatePolicyData {
    if (self.isEvaluateDataValid) {
        return self.evaluatePolicyData;
    }
    self.isEvaluateDataValid = YES;
    
    LAContext *context = [[LAContext alloc] init];
    NSError *error = nil;
    BOOL canEvaluatePolicy = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    self.evaluatePolicyData.currentSupportBiopaymentType = [self p_bioPaymentTypeWithContext:context canEvaluatePolicy:canEvaluatePolicy error:error];
    self.evaluatePolicyData.evaluatedPolicyDomainState = context.evaluatedPolicyDomainState;
    [self p_setEvaluatePolicyDataStateWithEerror:error];

    return self.evaluatePolicyData;
}

- (CJPayBioPaymentType)p_bioPaymentTypeWithContext:(LAContext *)context
                                 canEvaluatePolicy:(BOOL)canEvaluatePolicy
                                             error:(NSError *)error {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (canEvaluatePolicy){
            if (@available(iOS 11.0.1, *)) {
                //bugfix https://stackoverflow.com/questions/47588884/lacontext-biometrytype-unrecognized-selector-on-ios-11-0-0
                if (context.biometryType == LABiometryTypeFaceID) {
                    self.currentSupportBiopaymentType  = CJPayBioPaymentTypeFace; // 如果已经是faceID了  则肯定不支持touchID 了
                } else {
                    self.currentSupportBiopaymentType = CJPayBioPaymentTypeFinger;
                }
            } else {
                self.currentSupportBiopaymentType  = CJPayBioPaymentTypeFinger;
            }
        } else {
            self.currentSupportBiopaymentType = [self.class p_getSupportPaymentTypeWithError:error ctx:context];
        }
    });
    
    return self.currentSupportBiopaymentType;
}

// 配置策略评估数据
- (void)p_setEvaluatePolicyDataStateWithEerror:(NSError *)error {
    if (@available(iOS 11.0, *)) {
        self.evaluatePolicyData.isLockOut = error.code == LAErrorBiometryLockout;
//        self.evaluatePolicyData.isTouchIDNotEnrolled = error.code == LAErrorBiometryNotEnrolled;
        self.evaluatePolicyData.isBiometryNotAvailable = error.code == LAErrorBiometryNotAvailable ? YES : NO;
    } else {
        self.evaluatePolicyData.isLockOut = error.code == kLAErrorTouchIDLockout;
//        self.evaluatePolicyData.isTouchIDNotEnrolled = error.code == kLAErrorTouchIDNotEnrolled;
        self.evaluatePolicyData.isBiometryNotAvailable = error.code == kLAErrorTouchIDNotAvailable ? YES : NO;
    }
    
    self.evaluatePolicyData.isTouchIDNotEnrolled = !self.evaluatePolicyData.evaluatedPolicyDomainState && !self.evaluatePolicyData.isLockOut;
}

#pragma mark - Getter&Setter
- (CJPayTouchIDEvaluatePolicyData *)evaluatePolicyData {
    if (!_evaluatePolicyData) {
        _evaluatePolicyData = [CJPayTouchIDEvaluatePolicyData new];
    }
    return _evaluatePolicyData;
}

@end
