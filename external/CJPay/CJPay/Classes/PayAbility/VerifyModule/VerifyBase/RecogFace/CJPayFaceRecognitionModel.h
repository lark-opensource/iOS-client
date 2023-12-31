//
//  CJPayFaceRecognitionModel.h
//  人脸协议弹窗/全屏页model
//
//  Created by 孟源 on 2022/6/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, CJPayFaceRecognitionStyle) {
    CJPayFaceRecognitionStyleActivelyArouseInPayment,       // 支付流程主动唤起
    CJPayFaceRecognitionStyleOpenBioVerify,                 // 刷脸开通生物验证
    CJPayFaceRecognitionStyleExtraTestInPayment,            // 支付流程加验
    CJPayFaceRecognitionStyleExtraTestInBindCard,           // 绑卡流程加验
};

@interface CJPayFaceRecognitionModel : NSObject
//通用
@property (nonatomic, copy) NSString *agreementName;
@property (nonatomic, copy) NSString *agreementURL;
//弹窗用
@property (nonatomic, copy) NSString *protocolCheckBox;
@property (nonatomic, assign) CJPayFaceRecognitionStyle showStyle;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *buttonText;
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *bottomButtonText;
@property (nonatomic, assign) BOOL shouldShowProtocolView;
@property (nonatomic, assign) BOOL hideCloseButton;

//全屏页
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *userMaskName;
@property (nonatomic, copy) NSString *alivecheckScene;
@property (nonatomic, assign) NSInteger alivecheckType;

@end

NS_ASSUME_NONNULL_END
