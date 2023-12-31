//
//  ACCDuetLayoutViewController.h
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/2/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCDuetLayoutManager;
@class ACCDuetLayoutViewController;
@protocol ACCDuetLayoutViewControllerDelegate <NSObject>

@required
- (NSArray *)duetLayoutModels;
- (NSDictionary *)duetCommonTrackDic;

@optional
- (void)duetLayoutController:(ACCDuetLayoutViewController *)controller didSelectDuetLayoutAtIndex:(NSInteger)index;
- (void)duetLayoutController:(ACCDuetLayoutViewController *)controller didSwitchDuetLayoutAtIndex:(NSInteger)index;
- (void)duetLayoutController:(ACCDuetLayoutViewController *)controller didTapOnRetryButton:(UIButton *)sender;
- (void)duetLayoutController:(ACCDuetLayoutViewController *)controller didTapOnSwappedCameraButton:(UIButton *)button;

@end

@interface ACCDuetLayoutViewController : UIViewController

@property (nonatomic, copy) void(^dissmissBlock)(void);
@property (nonatomic, weak) id<ACCDuetLayoutViewControllerDelegate> delegate;
@property (nonatomic, assign) NSInteger currentSelectedIndex;
@property (nonatomic, assign) NSInteger firstTimeSelectedIndex;

- (void)showOnView:(UIView *)containerView;
- (void)reloadData;
- (void)forceSelectFirstLayoutIfNeeded;
- (void)showNetErrorView;
- (void)enableSwappedCameraButton:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
