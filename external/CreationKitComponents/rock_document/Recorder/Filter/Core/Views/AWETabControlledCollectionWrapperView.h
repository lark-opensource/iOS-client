//
//  AWETabControlledCollectionWrapperView.h
//  AWEStudio
//
//Created by Li Yansong on July 26, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

@class IESCategoryModel;
@class IESEffectModel;

#import <UIKit/UIKit.h>
#import "ACCOldFilterUIConfigurationProtocol.h"
#import <CreationKitInfra/ACCRecordFilterDefines.h>

@class AWEColorFilterDataManager;

@protocol AWETabControlledCollectionWrapperViewDelegate <NSObject>

- (void)clearFilterApply;
- (BOOL)shouldSelectFilter:(IESEffectModel *)item;
- (void)tabClickedWithName:(NSString *)tabName;
- (void)filterBoxButtonClicked;

@optional
// track use
- (void)didClickedCategory:(IESCategoryModel *)category;
- (void)didClickedFilter:(IESEffectModel *)item;

@end

FOUNDATION_EXTERN NSString * const ACCFilterTabNameMap;

//Contains a collectionview that can be controlled by tab
@interface AWETabControlledCollectionWrapperView : UIView

@property (nonatomic, copy) NSArray<NSDictionary<IESCategoryModel *, NSArray<IESEffectModel *> *> *> *filtersArray;
@property (nonatomic, weak) id<AWETabControlledCollectionWrapperViewDelegate> delegate;
@property (nonatomic, strong) IESEffectModel *selectedFilter;
@property (nonatomic, assign) BOOL enableSliderMaskImage;
@property (nonatomic, assign) AWEFilterCellIconStyle iconStyle;
@property (nonatomic, assign) BOOL showFilterBoxButton; //Whether to display the filter box management button (only on the shooting page)
@property (nonatomic, assign) BOOL shouldShowClearFilterButton; //Controls whether the clear filter application button needs to be displayed
@property (nonatomic, strong) AWEColorFilterDataManager *filterManager;

- (instancetype)initWithFrame:(CGRect)frame shouldShowClearFilterButton:(BOOL)shouldShowClearFilterButton
                filterManager:(AWEColorFilterDataManager *)filterManager;

- (void)scrollToEffect:(IESEffectModel *)effect;

- (void)selectFilterByCode:(IESEffectModel *)filter scrolling:(BOOL)scrolling;

- (void)reloadData;
- (void)reloadDataAndScrollingToSelected:(BOOL)scrolling;

/**
 * Query tabName by filter field
 */
- (NSString *)tabNameForFilter:(IESEffectModel *)filter;

- (void)updateTabNameCache:(NSArray<IESCategoryModel *> *)categoryModels;

- (void)updateEffect:(IESEffectModel *)effect;

- (void)selectClearButton;

- (void)updateUIConfig:(id<ACCOldFilterUIConfigurationProtocol>)config;

@end
