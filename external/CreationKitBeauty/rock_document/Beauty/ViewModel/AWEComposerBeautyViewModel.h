//
//  AWEComposerBeautyViewModel.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/1/19.
//

#import <Foundation/Foundation.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectViewModel.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitBeauty/ACCBeautyBuildInDataSource.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AWEComposerBeautyFetchDataBlock)(NSArray<AWEComposerBeautyEffectCategoryWrapper *> * _Nullable categories);
typedef void(^AWEComposerDownloadStatusChangedBlock)(AWEComposerBeautyEffectWrapper * _Nullable effectWrapper,AWEEffectDownloadStatus downloadStatus);

@interface AWEComposerBeautyViewModel : NSObject

@property (nonatomic,   copy, readonly) NSArray<AWEComposerBeautyEffectCategoryWrapper *> *filteredCategories;
@property (nonatomic, strong, readonly) AWEComposerBeautyEffectCategoryWrapper *currentCategory;
@property (nonatomic, strong, nullable) AWEComposerBeautyEffectWrapper *selectedEffect;
@property (nonatomic, strong, readonly) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong, readonly) AWEComposerBeautyEffectViewModel *effectViewModel;
@property (nonatomic,   copy) NSDictionary *referExtra;
@property (nonatomic,   copy, readonly) NSString *businessName;// DMT is empty by default, other products set - XS / multi flash
@property (nonatomic, strong) id<ACCBeautyBuildInDataSource> dataSource;

@property (nonatomic,   copy)AWEComposerBeautyFetchDataBlock fetchDataBlock;
@property (nonatomic,   copy)AWEComposerDownloadStatusChangedBlock downloadStatusChangedBlock;

// Configuration
@property (nonatomic, assign) BOOL prefersEnableBeautyCategorySwitch;

- (instancetype)initWithEffectViewModel:(AWEComposerBeautyEffectViewModel *)viewModel
                           businessName:(NSString *)businessName
                           publishModel:(AWEVideoPublishViewModel *)publishModel;

// fetch
- (void)fetchBeautyEffects;

// setter
- (void)setFilteredCategories:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)filteredCategories;
- (void)setCurrentCategory:(AWEComposerBeautyEffectCategoryWrapper *)currentCategory;

// reset
- (void)resetAllComposerBeautyEffects;
- (void)resetComposerCategoryAllItemToZero:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper;
- (void)resetAllComposerBeautyEffectsOfCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper;
- (BOOL)shouldDisableResetButton;
- (BOOL)isDefaultStatusCategory:(AWEComposerBeautyEffectCategoryWrapper *)category;


// switch
- (BOOL)enableBeautyCategorySwitch;
- (void)resetCategorySwitchState;

// primaryPanel
@property (nonatomic, assign, readonly) BOOL isPrimaryPanelEnabled;
- (void)enablePrimaryPanel;

@end

NS_ASSUME_NONNULL_END
