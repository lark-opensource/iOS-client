//
//  CJPayFaceRecogAlertViewController.h
//  Pods
//
//  Created by chenbocheng on 2022/1/13.
//

#import "CJPayPopUpBaseViewController.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayFaceRecogAlertContentView;
@class CJPayGetTicketResponse;
@class CJPayFaceRecognitionModel;

@interface CJPayFaceRecogAlertViewController : CJPayPopUpBaseViewController

@property (nonatomic, copy) void(^confirmBtnBlock)(void);
@property (nonatomic, copy) void(^closeBtnBlock)(void);
@property (nonatomic, copy) void(^bottomBtnBlock)(void);
@property (nonatomic, strong, readonly) CJPayFaceRecogAlertContentView *contentView;


- (instancetype)initWithFaceRecognitionModel:(CJPayFaceRecognitionModel *)model;
- (void)showOnTopVC:(UIViewController *)vc;
@end

NS_ASSUME_NONNULL_END
