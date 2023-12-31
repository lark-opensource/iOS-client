//
//  CJPayGuideResetPwdPopUpViewController.h
//  Aweme
//
//  Created by 尚怀军 on 2022/12/2.
//

#import "CJPayPopUpBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayBaseVerifyManager;
@class CJPayResultPageGuideInfoModel;
@interface CJPayGuideResetPwdPopUpViewController : CJPayPopUpBaseViewController

@property (nonatomic, weak) CJPayBaseVerifyManager *verifyManager;
@property (nonatomic, copy) void(^completeBlock)(void);
@property (nonatomic, copy) void(^trackerBlock)(NSString *, NSDictionary *);
@property (nonatomic, strong) CJPayResultPageGuideInfoModel *guideInfoModel;

@end

NS_ASSUME_NONNULL_END
