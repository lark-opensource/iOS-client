//
//  ACCSwipeUpGuideViewController.h
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/7/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCSwipeUpGuideViewController : UIViewController

@property (nonatomic, strong, readonly) UILabel *mainLabel;

- (void)showSwipeUpGuideOnTableView:(UITableView *)tableView;
- (void)showSwipeUpGuideOnTableView:(UITableView *)tableView containerView:(nullable UIView *)view;
- (void)dismissSwipeUpGuide;

@end

NS_ASSUME_NONNULL_END
