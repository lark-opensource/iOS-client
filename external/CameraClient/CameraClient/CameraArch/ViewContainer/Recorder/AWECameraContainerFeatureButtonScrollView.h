//
//  AWECameraContainerFeatureButtonScrollView.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/5/6.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWECameraContainerDefine.h"
#import <CreationKitArch/AWECameraContainerToolButtonWrapView.h>
#import <CreativeKit/ACCBarItemContainerView.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWECameraContainerFeatureButtonScrollView : UIView

/// TODO:这里看不懂那些provider什么的，理论上sortDataSource应该是个static的单例，现在先从外面传进来
@property (nonatomic, strong) id<ACCBarItemSortDataSource> sortDataSrouce;

@property (nonatomic, strong, readonly, nullable) NSMutableArray<AWECameraContainerToolButtonWrapView *> *activeButtons;// ordered array for active buttons

@property (nonatomic, strong, readonly, nullable) NSMutableArray<AWECameraContainerToolButtonWrapView *> *deactiveButtons;// ordered array for deactive buttons

@property (nonatomic, strong, readonly, nullable) NSArray<AWECameraContainerToolButtonWrapView *> *visibleButtons;// ordered array for active buttons

@property (nonatomic, copy, nullable) NSArray<AWECameraContainerToolButtonWrapView *> *allButtons; // ordered array for all buttons

/// custom add method

- (void)addFeatureView:(AWECameraContainerToolButtonWrapView *)featureView;

/// get view for the specific baritem
/// @param barItem
- (AWECameraContainerToolButtonWrapView *)getViewForBarItem:(ACCBarItem *)barItem;

/// needShowBlock - Action
- (void)insertItem:(ACCBarItem *)item;

- (void)removeItem:(ACCBarItem *)item;

/// insert mask View
- (void)insertMaskViewAboveToolBar:(UIView *)maskView;

NS_ASSUME_NONNULL_END

@end
