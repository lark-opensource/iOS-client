//
//  AWECameraFilterConfiguration.h
//  Aweme
//
//Created by Hao Yipeng on November 8, 2017
//  Copyright  ©  Byedance. All rights reserved, 2017
//

#import <CreationKitInfra/ACCRecordFilterDefines.h>
#import <TTVideoEditor/HTSFilterDefine.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectPlatformSDK/IESEffectModel.h>

@class AWEColorFilterDataManager;

@interface AWECameraFilterConfiguration : NSObject

- (instancetype)initWithFilterManager:(AWEColorFilterDataManager *)filterManager;

@property (nonatomic, strong, readonly) AWEColorFilterDataManager *filterManager;

@property (nonatomic, copy, readonly) NSArray *filterArray;
@property (nonatomic, copy, readonly) NSArray *aggregatedEffects;

@property (nonatomic, strong) IESEffectModel *frontCameraFilter;
@property (nonatomic, strong) IESEffectModel *rearCameraFilter;

@property (nonatomic, strong) IESEffectModel *needRecoveryFrontCameraFilter;
@property (nonatomic, strong) IESEffectModel *needRecoveryRearCameraFilter;

@property (nonatomic, assign) BOOL fetchDataOpt;

- (void)updateFilterData;
- (void)updateFilterDataWithCompletion:(dispatch_block_t)completion;

- (void)fetchEffectListStateCompletion:(EffectPlatformFetchListCompletionBlock)completion;
- (void)updateFilterCheckStatusWithCheckArray:(NSArray *)checkArray uncheckArray:(NSArray *)uncheckArray;

@end
