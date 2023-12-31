//
//  CJPayBindCardFirstStepViewController.h
//  Pods
//
//  Created by renqiang on 2021/6/28.
//

#import "CJPayBindCardBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPayBindCardQuickFrontFirstStepModel : BDPayBindCardBaseViewModel

@property (nonatomic, copy) NSString *jumpQuickBindCard;
@property (nonatomic, copy) NSString *orderAmount;
@property (nonatomic, copy) NSString *isShowOrderInfo;
@property (nonatomic, copy) NSString *backgroundImageURL;

@end


@interface CJPayBindCardFirstStepViewController : CJPayBindCardBaseViewController

@property (nonatomic, assign) BOOL forceShowTopSafe;

@end

NS_ASSUME_NONNULL_END
