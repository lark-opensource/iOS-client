//
//  AWETabFilterViewController.h
//  AWEStudio
//
//Created by Li Yansong on July 27, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import <UIKit/UIKit.h>
#import "AWERecordFilterViewControllerDelegate.h"
#import <CreativeKit/ACCPanelViewProtocol.h>
#import "ACCOldFilterUIConfigurationProtocol.h"
#import <CreationKitInfra/ACCRecordFilterDefines.h>

@class AWECameraFilterConfiguration;
@class IESCategoryModel;
@class IESEffectModel;
@class AWEColorFilterDataManager;
@protocol ACCFilterDataService;

//Show the viewcontroller of the sub tab filter
@interface AWETabFilterViewController : UIViewController <ACCPanelViewProtocol>

//Whether to display filter and beauty switch button
@property(nonatomic, copy) void(^willDismissBlock)(void);
@property(nonatomic, copy) void(^didDismissBlock)(void);
@property(nonatomic, copy) NSArray<NSDictionary<IESCategoryModel *, NSArray<IESEffectModel *> *> *> *filtersArray;
@property(nonatomic, weak) id<AWERecordFilterVCDelegate> delegate;
@property(nonatomic, strong) IESEffectModel *selectedFilter;
//The requirement of atlas editing is that the filter of each image is applied separately, so the previous logic cannot be reused
//If the image has been applied with a filter, the current applied intensity is displayed instead of the last selected intensity
//In fact, video or other services can also be used. In theory, businesses should manage their own data instead of putting it in view?
@property(nonatomic, strong) NSNumber *selectedFilterIntensityRatio;
@property(nonatomic, assign) BOOL isPhotoMode;
@property(nonatomic, strong) id<ACCFilterDataService> repository;
@property (nonatomic, assign) BOOL showOnViewController;
@property (nonatomic, assign) BOOL showFilterBoxButton;
@property (nonatomic, assign) BOOL needDismiss;
@property (nonatomic, strong) AWEColorFilterDataManager *filterManager;
@property (nonatomic, assign) AWEFilterCellIconStyle iconStyle;
@property (nonatomic, strong, readonly) UIView *containerView;
@property (nonatomic, readonly) UIView *bottomTabFilterView;

- (instancetype)initWithFilterConfiguration:(AWECameraFilterConfiguration *)filterConfiguration;

- (void)showOnViewController:(UIViewController *)controller;
- (void)showOnView:(UIView *)view;

- (void)selectFilterByCode:(IESEffectModel *)filter;

- (void)reloadData;

- (NSString *)tabNameForFilter:(IESEffectModel *)filter;

- (void)updateUIConfig:(id<ACCOldFilterUIConfigurationProtocol>)config;

@end
