//
//  ACCSlidingTabViewController.h
//  CameraClient
//
//  Created by long.chen on 2020/3/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCSlidingTabViewController, ACCSlidingViewController, AWEVideoPublishViewModel;


@protocol ACCSlidingTabViewControllerProtocol <NSObject>


@end


@protocol ACCWaterfallTabContentProviderProtocol <NSObject>

@property (nonatomic, weak) UIViewController<ACCSlidingTabViewControllerProtocol> *viewController;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;

- (NSUInteger)initialSelectedIndex;
- (NSArray<NSString *> *)tabTitlesArray;
- (NSArray<UIViewController *> *)slidingViewControllers;

- (void)slidingViewController:(ACCSlidingViewController *)slidingViewController didSelectIndex:(NSInteger)index;

@end


@interface ACCSlidingTabViewController : UIViewController <ACCSlidingTabViewControllerProtocol>

@property (nonatomic, strong) id<ACCWaterfallTabContentProviderProtocol> contentProvider;

// 一键成片
- (void)registerOneKeyButton:(UIButton *)button finalY:(CGFloat)finalY;

@end

NS_ASSUME_NONNULL_END
