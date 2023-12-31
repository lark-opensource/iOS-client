//
//  CJPayIAPRetainPopUpViewController.h
//  Aweme
//
//  Created by chenbocheng.moon on 2023/2/28.
//

#import "CJPayPopUpBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayIAPRetainPopUpViewController : CJPayPopUpBaseViewController

@property (nonatomic, copy) void(^clickConfirmBlock)(void);
@property (nonatomic, copy) void(^clickHelpBlock)(void);
@property (nonatomic, copy) void(^clickCancelBlock)(void);

- (instancetype)initWithTitle:(NSString *)title content:(NSString *)content;
- (void)showOnTopVC:(UIViewController *)vc;

@end

NS_ASSUME_NONNULL_END
