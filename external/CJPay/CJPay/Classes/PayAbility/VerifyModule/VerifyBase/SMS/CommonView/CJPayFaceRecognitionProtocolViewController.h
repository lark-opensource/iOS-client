//
//  CJPayFaceRecognitionProtocolViewController.h
//  CJPay
//
//  Created by 尚怀军 on 2020/8/18.
//

#import "CJPayFullPageBaseViewController.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayFaceRecognitionModel;
@interface CJPayFaceRecognitionProtocolViewController : CJPayFullPageBaseViewController

@property (nonatomic, copy) void(^signSuccessBlock)(NSString *ticket);
@property (nonatomic, weak) id<CJPayTrackerProtocol> trackDelegate; // 埋点上报代理
@property (nonatomic, assign) BOOL shouldCloseCallBack;

- (instancetype) initWithFaceRecognitionModel:(CJPayFaceRecognitionModel *)model;
@end

NS_ASSUME_NONNULL_END
