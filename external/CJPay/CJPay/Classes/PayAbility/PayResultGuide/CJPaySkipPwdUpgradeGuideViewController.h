//
//  CJPaySkipPwdUpgradeGuideViewController.h
//  Pods
//
//  Created by bytedance on 2022/7/27.
//

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayResultPageGuideInfoModel;
@class CJPayBaseVerifyManager;
@interface CJPaySkipPwdUpgradeGuideViewController : CJPayHalfPageBaseViewController

@property (nonatomic, strong) CJPayBaseVerifyManager *verifyManager;
@property (nonatomic, strong) CJPayResultPageGuideInfoModel *model;

@property (nonatomic, assign) BOOL isTradeCreateAgain;

@property (nonatomic, copy) void(^completion)(void);

- (instancetype)initWithGuideInfoModel:(CJPayResultPageGuideInfoModel *)model;


@end

NS_ASSUME_NONNULL_END
