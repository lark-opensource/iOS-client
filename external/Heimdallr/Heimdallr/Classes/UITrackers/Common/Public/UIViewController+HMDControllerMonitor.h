//
//  UIViewController+HMDControllerMonitor.h
//  Heimdallr
//
//  Created by joy on 2018/5/14.
//

#import <UIKit/UIKit.h>

@interface UIViewController (HMDControllerMonitor)

@property (nonatomic, strong, nullable) NSNumber *hmdViewDidLoadStartTime;
@property (nonatomic, strong, nullable) NSNumber *hmdViewWillAppearStartTime;
@property (nonatomic, strong, nullable) NSNumber *hmdViewDidAppearStartTime;
@property (nonatomic, strong, nullable) NSNumber *hmdLoadViewStartTime;
@property (nonatomic, strong, nullable) NSNumber *hmdPageInitStartTime;
@property (nonatomic, strong, nullable) NSNumber *hmdIsFirstOpen;

@property (nonatomic, strong, nullable) NSNumber *hmdViewDidLoadTime;
@property (nonatomic, strong, nullable) NSNumber *hmdViewWillAppearTime;
@property (nonatomic, strong, nullable) NSNumber *hmdLoadViewTime;

// 暂时一写，后期根据需要改名
- (void)didFinishConcurrentRendering;
- (void)didFnishConcurrentRendering __attribute__((deprecated("please use didFinishConcurrentRendering")));

- (void)hmd_initActionStart;
- (void)hmd_initViewActionEnd;

- (void)hmd_loadViewActionStart;
- (void)hmd_loadViewActionEnd;

- (void)hmd_viewDidLoadActionStart;
- (void)hmd_viewDidLoadActionEnd;
- (void)hmd_viewWillAppearActionStart;
- (void)hmd_viewWillAppearActionEnd;
- (void)hmd_viewDidAppearActionStart;
- (void)hmd_viewDidAppearActionEnd;
@end
