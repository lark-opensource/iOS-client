//
//  CJPayCardOCRViewController.h
//  CJPay
//
//  Created by 尚怀军 on 2020/5/12.
//

#import "CJPayFullPageBaseViewController.h"
#import "CJPayCardOCRResultModel.h"
#import "CJPayCardOCRUtil.h"
#import "CJPaySafeUtil.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayOCRScanWindowView.h"
#import "CJPayTrackerProtocol.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, CJPayCardOCRSampleMethods) {
    CJPayCardOCRSampleMethodFixTimeInterval = 1 << 0,   // 固定时间间隔聚焦采样
    CJPayCardOCRSampleMethodSubjectAreaChange = 1 << 1, // 取景区域改变聚焦采样
};

typedef NS_ENUM(NSUInteger, CJPayOCRType) {
    CJPayOCRTypeBankCard = 1,
    CJPayOCRTypeIDCard
};

#define CJ_OCR_TIME_OUT_INTERVAL 30
#define CJ_OCR_IMG_ZIP_SIZE 150.0

typedef void(^CJPayCardOCRCompletionBlock)(CJPayCardOCRResultModel *resultModel);

@interface CJPayOCRBPEAData : NSObject
// BPEA证书名称，由客户端本地写死
@property (nonatomic, copy) NSString *requestAccessPolicy; //请求相机权限
@property (nonatomic, copy) NSString *jumpSettingPolicy;    //跳转系统设置
@property (nonatomic, copy) NSString *startRunningPolicy;   //启动录制
@property (nonatomic, copy) NSString *stopRunningPolicy;    //结束录制
// 用于标识前端业务场景，当通过jsb调OCR时会赋值，类型为TTBridgeCommand
@property (nonatomic, weak) id bridgeCommand;

@end

@interface CJPayCardOCRViewController : CJPayFullPageBaseViewController<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy, nullable) CJPayCardOCRCompletionBlock completionBlock;

// access by derived class
@property (nonatomic, strong) CJPayOCRScanWindowView *ocrScanView;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, assign) BOOL isCardRecognized;
@property (nonatomic, assign) BOOL recognizeEnable;
@property (atomic, assign) BOOL shouldCaptureImg;
// ABTest: auto exposure
@property (nonatomic, assign) BOOL enableAutoExpose; //ABTest, 是否自动调节曝光
@property (nonatomic, assign) BOOL enableSampleBufferDetection; // ABTest，是否开启采样缓冲区有效性检测
// ABTest: visionkit
@property (nonatomic, assign) BOOL enableLocalScan;
@property (nonatomic, assign) BOOL enableLocalPhotoUpload;
@property (nonatomic, assign) int serverBackupTime;
@property (nonatomic, assign) CJPayOCRType ocrType;

// 超时弹窗的timer
@property (nonatomic, strong, nullable) NSTimer *alertTimer;

@property (nonatomic, weak) id<CJPayTrackerProtocol> trackDelegate; // 埋点上报代理

@property (nonatomic, strong) CJPayOCRBPEAData *BPEAData;

- (void)setupUI;
- (void)resetAlertTimer;
- (void)trackWithEventName:(NSString *)eventName params:(nullable NSDictionary *)params specificOCRType:(CJPayOCRType)ocrType;
- (void)trackWithEventName:(NSString *)eventName params:(nullable NSDictionary *)params;
- (void)superBack;
- (void)completionCallBackWithResult:(CJPayCardOCRResultModel *)resultModel;
- (void)alertTimeOut;
- (void)switchFlashLight;  //埋点需要暴露o(╥﹏╥)o
- (void)startSession;
- (void)stopSession;
    
@end

NS_ASSUME_NONNULL_END
