//
//  CJPaySkipPwdGuideFigureViewController.h
//  Pods
//
//  Created by chenbocheng on 2021/12/14.
//

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayResultPageGuideInfoModel;
@class CJPayBaseVerifyManager;
@interface CJPaySkipPwdGuideFigureViewController : CJPayHalfPageBaseViewController

@property (nonatomic, strong) CJPayBaseVerifyManager *verifyManager;
@property (nonatomic, strong) CJPayResultPageGuideInfoModel *model;

@property (nonatomic, assign) BOOL isTradeCreateAgain;

@property (nonatomic, copy) void(^completeBlock)(void);

- (instancetype)initWithGuideInfoModel:(CJPayResultPageGuideInfoModel *)model;

@end

NS_ASSUME_NONNULL_END
