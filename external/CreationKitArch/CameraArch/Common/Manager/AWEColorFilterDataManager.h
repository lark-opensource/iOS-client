//
//  AWEEffectFilterDataManager.h
//  AWEStudio
//
//  Created by liubing on 19/04/2018.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>
#import <CreationKitInfra/ACCRecordFilterDefines.h>
#import <CreationKitArch/AWEColorFilterConfigurationHelper.h>
#import <CreationKitInfra/ACCRecordFilterDefines.h>

@class IESCategoryModel, IESEffectModel;

extern NSString *const kAWEStudioColorFilterUpdateNotification;
extern NSString *const kAWEStudioColorFilterListUpdateNotification;

@protocol AWEColorFilterDataManager <NSObject>

@property (nonatomic, strong, readonly) IESEffectModel *frontCameraFilter;
@property (nonatomic, strong, readonly) IESEffectModel *rearCameraFilter;
@property (nonatomic, strong, readonly) IESEffectModel *normalFilter;
@property (nonatomic, assign, readonly) BOOL enableComposerFilter;

@property (nonatomic, copy, readonly) NSString *panel;

+ (instancetype)defaultManager;
- (instancetype)initWithEnableComposerFilter:(BOOL)enableComposerFilter;

- (void)updateEffectFilters;
// modify panel name
- (void)updatePanelName:(NSString *)panelName;

- (NSArray<IESEffectModel *> *)availableEffects;
- (IESEffectModel *)effectWithID:(NSString *)effectId; // Per manager lookup
+ (IESEffectModel *)effectWithID:(NSString *)effectId; // Look up from all managers

- (NSArray<NSDictionary<IESCategoryModel *, NSArray<IESEffectModel *> *> *> *)aggregatedEffects;
- (NSArray<NSDictionary<IESCategoryModel *, NSArray<IESEffectModel *> *> *> *)allAggregatedEffects;
- (NSArray<IESEffectModel *> *)flattenedAggregatedEffects;

+ (void)loadEffectWithID:(NSString *)effectId completion:(void (^)(IESEffectModel *))completion;
- (void)fetchEffectListStateCompletion:(EffectPlatformFetchListCompletionBlock)completion;
- (void)updateEffectListStateWithCheckArray:(NSArray *)checkArray uncheckArray:(NSArray *)uncheckArray;

+ (IESEffectModel *)prevFilterOfFilter:(IESEffectModel *)filter filterArray:(NSArray *)filterArray;
+ (IESEffectModel *)nextFilterOfFilter:(IESEffectModel *)filter filterArray:(NSArray *)filterArray;
- (AWEEffectDownloadStatus)downloadStatusOfEffect:(IESEffectModel *)effect;
- (void)addEffectToDownloadQueue:(IESEffectModel *)effectModel;

- (AWEColorFilterConfigurationHelper *)colorFilterConfigurationHelperWithType:(AWEColorFilterConfigurationType)type;

- (void)injectBuildInFilterArrayBlock:(nullable NSArray<IESEffectModel *> *(^)(void))block;

@end

@interface AWEColorFilterDataManager : NSObject <AWEColorFilterDataManager>

@property (nonatomic, assign) ACCFilterPanelType filterPanelType;

@end
