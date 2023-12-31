//
//  CJPayBioSystemSettingGuideViewController.h
//  CJPay-CJPayDemoTools-Example
//
//  Created by liwenyou on 2022/6/18.
//

#import "CJPayHalfPageBaseViewController.h"

@class CJPayBaseVerifyManager;
@class CJPayResultPageGuideInfoModel;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBioSystemSettingGuideViewController : CJPayHalfPageBaseViewController

@property (nonatomic, strong) CJPayBaseVerifyManager *verifyManager;
@property (nonatomic, copy) void(^completeBlock)(void);

- (instancetype)initWithGuideInfoModel:(CJPayResultPageGuideInfoModel *)model;

@end

NS_ASSUME_NONNULL_END
