//
//  BytedCertManager+Private.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/10.
//

#import "BytedCertManager.h"
#import "BDCTFaceVerificationFlow.h"
#import "BytedCertUIConfig.h"

@class BytedCertError;

#define BytedCertSDKVersion BytedCertManager.sdkVersion

#define BDCTShowLoading BDCTShowLoadingWithToast(BytedCertLocalizedString(@"加载中..."))

#define BDCTShowLoadingWithToast(toast) [BytedCertManager showToastWithText:toast type:BytedCertToastTypeLoading]

#define BDCTDismissLoading [BytedCertManager showToastWithText:nil type:BytedCertToastTypeNone]

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BytedCertDeviceNFCStatus) {
    BytedCertDeviceNFCStatusNone = 0,     //未获取到是否支持NFC状态
    BytedCertDeviceNFCStatusSupport = 1,  //设备支持NFC
    BytedCertDeviceNFCStatusUnSupport = 2 //设备不支持支持NFC
};


@interface BytedCertManager (Private)

@property (nonatomic, assign) BOOL hasInited;

@property (nonatomic, assign) BOOL useAPIV3;

@property (nonatomic, copy) NSString *latestTicket;

@property (nonatomic, assign) CGFloat statusBarHeight;

@property (nonatomic, assign) BytedCertDeviceNFCStatus nfcSupport;

@property (nonatomic, copy) void (^uiConfigBlock)(BytedCertUIConfigMaker *_Nonnull maker);

+ (NSString *)aid;

+ (NSString *)appName;

+ (instancetype)shareInstance;

+ (BytedCertDeviceNFCStatus)deviceSupportNFC;

/// 仅唤起人脸验证
/// @param parameter 参数
/// @param shouldBeginFaceVerification 是否继续唤起人脸
/// @param completion 回调
- (void)p_beginFaceVerificationWithParameter:(BytedCertParameter *)parameter
                          fromViewController:(UIViewController *_Nullable)fromViewController
                                forcePresent:(BOOL)forcePresent
                                   suprtFlow:(BDCTFlow *_Nullable)superFlow
                 shouldBeginFaceVerification:(nullable BOOL (^)(void))shouldBeginFaceVerification
                                  completion:(nullable void (^)(BytedCertError *_Nullable, NSDictionary *_Nullable))completion;

- (void)saveStatusBarHeight;

@end


@interface BytedCertManager (PrivateUI)

+ (void)showToastWithText:(NSString *_Nullable)text type:(BytedCertToastType)type;

+ (void)showAlertOnViewController:(UIViewController *)viewController title:(NSString *_Nullable)title message:(NSString *_Nullable)message actions:(NSArray<BytedCertAlertAction *> *)actions;

@end

NS_ASSUME_NONNULL_END
