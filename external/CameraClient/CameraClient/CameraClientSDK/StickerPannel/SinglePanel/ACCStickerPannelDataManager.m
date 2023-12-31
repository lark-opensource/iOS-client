//
//  ACCStickerPannelDataManager.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/8/18.
//

#import "ACCStickerPannelDataManager.h"

#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCConfigManager.h>

static const NSInteger kACCStickerPannelPaginationDefaultPageCount = 20;

@implementation ACCStickerPannelDataPagination

@end

@interface ACCStickerPannelDataManager ()

@end

@implementation ACCStickerPannelDataManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _pageCount = kACCStickerPannelPaginationDefaultPageCount;
    }
    return self;
}

#pragma mark - support pagination

- (void)fetchPanelCategories:(void(^)(BOOL downloadSuccess, NSArray<IESCategoryModel *> *stickerCategories))completion
{
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    
    @weakify(self);
    [EffectPlatform checkPanelUpdateWithPanel:self.pannelName effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        IESEffectPlatformNewResponseModel *response = [EffectPlatform cachedCategoriesOfPanel:self.pannelName];
        if (!needUpdate && response.categoryEffects.effects.count) {
            [self.logger logPannelUpdateFailed:self.pannelName updateDuration:CFAbsoluteTimeGetCurrent() - startTime];
            ACCBLOCK_INVOKE(completion, YES, response.categories);
        } else {            
            CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
            [EffectPlatform fetchCategoriesListWithPanel:self.pannelName isLoadDefaultCategoryEffects:YES defaultCategory:@"" pageCount:self.pageCount cursor:0 effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel* _Nullable response) {
                @strongify(self);
                BOOL success = !error && response.categoryEffects.effects.count > 0;
                
                [self.logger logPannelUpdateFinished:self.pannelName needUpdate:YES updateDuration:CFAbsoluteTimeGetCurrent() - startTime success:success error:error];

                if (success) {
                    ACCBLOCK_INVOKE(completion, YES, response.categories);
                } else {
                    ACCBLOCK_INVOKE(completion, NO, nil);
                }
            }];
        }
    }];
}

- (void)fetchCategoryStickers:(NSString *)categoryKey
                   completion:(void(^)(BOOL downloadSuccess, NSArray<IESEffectModel *> *effects, ACCStickerPannelDataPagination *pagination))completion
{
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();

    @weakify(self);
    [EffectPlatform fetchCategoriesListWithPanel:self.pannelName isLoadDefaultCategoryEffects:YES defaultCategory:categoryKey pageCount:self.pageCount cursor:0 effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel* _Nullable response) {
        @strongify(self);
        BOOL success = !error && response.categoryEffects.effects.count > 0;

        [self.logger logPannelUpdateFinished:self.pannelName needUpdate:YES updateDuration:CFAbsoluteTimeGetCurrent() - startTime success:success error:error];

        if (success) {
            ACCBLOCK_INVOKE(completion, YES, response.categoryEffects.effects, [self pagenatinoWith:response]);
        } else {
            ACCBLOCK_INVOKE(completion, NO, nil, nil);
        }
    }];
}

- (void)loadMoreStckerWithCategory:(NSString *)category
                              page:(ACCStickerPannelDataPagination *)page
                        completion:(void(^)(BOOL downloadSuccess, NSArray<IESEffectModel *> *effects, ACCStickerPannelDataPagination *pagination))completion
{
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    @weakify(self);
    void (^requestCompletion)(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) = ^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
        @strongify(self);
        BOOL success = !error && response.categoryEffects.effects.count > 0;
        [self.logger logPannelUpdateFinished:self.pannelName needUpdate:YES updateDuration:CFAbsoluteTimeGetCurrent() - startTime success:success error:error];

        if (success) {
            ACCBLOCK_INVOKE(completion, YES, response.categoryEffects.effects, [self pagenatinoWith:response]);
        } else {
            ACCBLOCK_INVOKE(completion, NO, nil, nil);
        }
    };
    
    IESEffectPlatformNewResponseModel *response = [EffectPlatform cachedEffectsOfPanel:self.pannelName category:category cursor:page.cursor sortingPosition:page.sortingPosition];
    if (response.categoryEffects.effects.count) {
        ACCBLOCK_INVOKE(requestCompletion, nil, response);
    } else {
        [EffectPlatform downloadEffectListWithPanel:self.pannelName category:category pageCount:self.pageCount cursor:page.cursor sortingPosition:page.sortingPosition effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:requestCompletion];
    }
}

- (ACCStickerPannelDataPagination *)pagenatinoWith:(IESEffectPlatformNewResponseModel *)response {
    ACCStickerPannelDataPagination *page = [ACCStickerPannelDataPagination new];
    page.cursor = response.categoryEffects.cursor;
    page.hasMore = response.categoryEffects.hasMore;
    page.sortingPosition = response.categoryEffects.sortingPosition;
    return page;
}

@end
