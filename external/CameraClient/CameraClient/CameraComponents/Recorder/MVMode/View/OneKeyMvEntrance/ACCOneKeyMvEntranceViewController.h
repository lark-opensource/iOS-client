//
//  ACCOneKeyMvEntranceViewController.h
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/10/9.
//

#import <UIKit/UIKit.h>
#import <CreationKitInfra/ACCSlidingTabbarView.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCWaterfallViewController.h"
#import "ACCOneKeyMvEntranceView.h"
#import "ACCSlidingTabViewController.h"

@class AWEVideoPublishViewModel;

typedef NS_ENUM(NSUInteger, ACCOneKeyMvEntranceBannerStatus) {
    ACCOneKeyMvEntranceBannerHiden = 1,
    ACCOneKeyMvEntranceBannerShow = 2,
    ACCOneKeyMvEntranceBannerScrolling = 3,
};

@interface ACCOneKeyMvEntranceViewController : UIViewController <ACCOneKeyMvEntranceViewDelegate, ACCWaterfallContentScrollDelegate>

+ (instancetype)slidingTabView:(nullable ACCSlidingTabbarView *)slidingTabView
               contentProvider:(nullable id<ACCWaterfallTabContentProviderProtocol>)contentProvider;

- (instancetype)initWithSlidingTabView:(nullable ACCSlidingTabbarView *)slidingTabView
                       contentProvider:(nullable id<ACCWaterfallTabContentProviderProtocol>)contentProvider;

- (void)setupUpdateContentOffsetBlock:(nullable ACCWaterfallViewController *)vc;

- (void)registerOneKeyButton:(nullable UIButton *)button finalY:(CGFloat)finalY;

@end
