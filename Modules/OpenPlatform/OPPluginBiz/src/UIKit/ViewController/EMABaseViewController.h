//
//  EMABaseViewController.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/3.
//

#import <UIKit/UIKit.h>
#import <TTRoute/TTRoute.h>

// 仅用于手动设置status bar方向时使用，在调用setStatusBarOrientation:animated:前立即修改为YES，调用后立即修改为NO
extern BOOL EMA_STATUS_BAR_ORIENTATION_MODIFY;

typedef NS_ENUM(NSUInteger, EMAViewControllerStatsBarStyle)
{
    EMAViewControllerStatsBarNoneStyle,
    EMAViewControllerStatsBarDayBlackNightWhiteStyle,
    EMAViewControllerStatsBarDayWhiteNightBlackStyle,
};

typedef void (^EMAAppPageCompletionBlock)(id);

@interface EMABaseViewController : UIViewController <TTRouteInitializeProtocol>

@property(nonatomic, assign)BOOL viewBoundsChangedNotifyEnable;
// default to ModeChangeActionTypeCustom
//@property(nonatomic, assign)ModeChangeActionType modeChangeActionType;
@property(nonatomic, assign)EMAViewControllerStatsBarStyle statusBarStyle;

- (void)dismissSelf;


@end
