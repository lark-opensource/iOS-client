//
//  CJPaySMSVerificationRequestModel.h
//  CJPay
//
//  Created by liyu on 2020/7/12.
//

#import <JSONModel/JSONModel.h>

#import "CJPayHalfPageBaseViewController.h"

@interface CJPaySMSVerificationRequestModel : JSONModel

// jsb 参数
@property (nonatomic, copy) NSString *phoneNumberText;
@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *qaURLString;
@property (nonatomic, copy) NSString *qaTitle;

@property (nonatomic, assign) NSUInteger codeCount;
@property (nonatomic, assign) NSInteger countDownSeconds;

@property (nonatomic, assign) HalfVCEntranceType animationType;
@property (nonatomic, assign) BOOL usesCloseButton;
@property (nonatomic, copy) NSString *identify;


@end
