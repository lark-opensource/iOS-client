//
//  AWEEmojiStickerDataManager.m
//  CameraClient
//
//  Created by HuangHongsen on 2020/2/6.
//

#import "AWEEmojiStickerDataManager.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreationKitArch/ACCStudioServiceProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/ACCMacros.h>

#define AWEInformationStickeEmojiPanelName @"emoji-ios"
#define AWEInformationStickeEmojiPageCount 100

@interface AWEEmojiStickerDataManager()

@property (nonatomic, assign) BOOL isRequestOnAir;
@property (nonatomic, strong) NSMutableArray *completionArray;

@property (nonatomic, copy, readwrite) NSArray<IESCategoryModel *> *emojiCategories;
@property (nonatomic, copy, readwrite) NSArray<IESEffectModel *> *emojiEffects;
@property (nonatomic, strong) NSMutableArray<IESEffectModel *> *emojiTmpEffects;
@property (nonatomic, strong) IESCategoryEffectsModel *emojiCategoryEffects;
@property (nonatomic, assign, readwrite) BOOL emojiHasMore;
@property (nonatomic, assign, readwrite) NSInteger emojiCursor;
@property (nonatomic, assign, readwrite) NSInteger emojiSortingPosition;

@end

@implementation AWEEmojiStickerDataManager

#pragma mark - Singleton

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isRequestOnAir = NO;
        _completionArray = [NSMutableArray array];
        
        [IESAutoInline(ACCBaseServiceProvider(), ACCStudioServiceProtocol) preloadInitializationEffectPlatformManager];
    }
    return self;
}

+ (instancetype)defaultManager
{
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

#pragma mark - Data Fetching

- (void)downloadEmojisWithCompletion:(void (^)(BOOL))completion
{
    if (completion) {
        [self.completionArray addObject:completion];
    }
    
    if (self.isRequestOnAir) {
        return;
    }
    
    void(^completionWrapper)(BOOL downloadSuccess) = ^(BOOL downloadSuccess) {
        NSArray *completionArray = self.completionArray.copy;
        [completionArray enumerateObjectsUsingBlock:^(void(^obj)(BOOL downloadSuccess), NSUInteger idx, BOOL * _Nonnull stop) {
            ACCBLOCK_INVOKE(obj, downloadSuccess);
        }];
        
        [self.completionArray removeAllObjects];
        self.isRequestOnAir = NO;
    };
    
    NSString *emojiPanel = AWEInformationStickeEmojiPanelName;
    @weakify(self);
    // check and download emoji
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    [EffectPlatform checkEffectUpdateWithPanel:emojiPanel effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        IESEffectPlatformResponseModel *response = [EffectPlatform cachedEffectsOfPanel:emojiPanel];
        if (!needUpdate && response.effects.count) {
            [self.logger logPannelUpdateFailed:emojiPanel updateDuration:CFAbsoluteTimeGetCurrent() - startTime];
            
            self.emojiCategories = response.categories;
            self.emojiEffects = response.effects;
            self.requestID = response.requestID;
            ACCBLOCK_INVOKE(completionWrapper, YES);
        } else {
            self.isRequestOnAir = YES;
            
            CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
            [EffectPlatform downloadEffectListWithPanel:emojiPanel effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                @strongify(self);
                
                BOOL success = !error && response.effects.count > 0;
                [self.logger logPannelUpdateFinished:emojiPanel needUpdate:YES updateDuration:CFAbsoluteTimeGetCurrent() - startTime success:success error:error];
                if (success) {                                        
                    self.emojiCategories = response.categories;
                    self.emojiEffects = response.effects;
                    self.requestID = response.requestID;
                    ACCBLOCK_INVOKE(completionWrapper, YES);
                } else {                                              
                    ACCBLOCK_INVOKE(completionWrapper, NO);
                }
            }];
        }
    }];
}

#pragma mark - 支持emoji分页

- (void)fetchEmojiPanelCategoriesAndDefaultEffects:(void(^)(BOOL downloadSuccess))completion
{
    if (completion) {
        [self.completionArray addObject:completion];
    }
    
    if (self.isRequestOnAir) {
        return;
    }
    
    void(^completionWrapper)(BOOL downloadSuccess) = ^(BOOL downloadSuccess) {
        NSArray *completionArray = self.completionArray.copy;
        [completionArray enumerateObjectsUsingBlock:^(void(^obj)(BOOL downloadSuccess), NSUInteger idx, BOOL * _Nonnull stop) {
            ACCBLOCK_INVOKE(obj, downloadSuccess);
        }];
        
        [self.completionArray removeAllObjects];
        self.isRequestOnAir = NO;
    };
    
    NSString *emojiPanel = AWEInformationStickeEmojiPanelName;
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    
    @weakify(self)
    [EffectPlatform checkPanelUpdateWithPanel:emojiPanel effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        IESEffectPlatformNewResponseModel *response = [EffectPlatform cachedCategoriesOfPanel:emojiPanel];
        @strongify(self)
        if (!needUpdate && response.categoryEffects.effects.count) {
            [self.logger logPannelUpdateFailed:emojiPanel updateDuration:CFAbsoluteTimeGetCurrent() - startTime];
            
            self.emojiCategories = response.categories;
            [self updateEmojiPagingInfoWithResponse:response isLoadMore:NO];
            [self autoLoadCachedEmojis];
            ACCBLOCK_INVOKE(completionWrapper, YES);
        } else {
            self.isRequestOnAir = YES;
            
            CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
            [EffectPlatform fetchCategoriesListWithPanel:emojiPanel isLoadDefaultCategoryEffects:YES defaultCategory:@"" pageCount:AWEInformationStickeEmojiPageCount cursor:0 effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel* _Nullable response) {
                BOOL success = !error && response.categoryEffects.effects.count > 0;
                
                [self.logger logPannelUpdateFinished:emojiPanel needUpdate:YES updateDuration:CFAbsoluteTimeGetCurrent() - startTime success:success error:error];

                if (success) {
                    self.emojiCategories = [response.categories copy];
                    [self updateEmojiPagingInfoWithResponse:response isLoadMore:NO];
                    if (!needUpdate) {
                        [self autoLoadCachedEmojis];
                    }
                    ACCBLOCK_INVOKE(completionWrapper, YES);
                } else {
                    ACCBLOCK_INVOKE(completionWrapper, NO);
                }
            }];
        }
    }];
}

- (void)loadMoreEmojisWithCompletion:(void(^)(BOOL downloadSuccess))completion
{
    if (completion) {
        [self.completionArray addObject:completion];
    }
    
    if (self.isRequestOnAir) {
        return;
    }
    
    void(^completionWrapper)(BOOL downloadSuccess) = ^(BOOL downloadSuccess) {
        NSArray *completionArray = self.completionArray.copy;
        [completionArray enumerateObjectsUsingBlock:^(void(^obj)(BOOL downloadSuccess), NSUInteger idx, BOOL * _Nonnull stop) {
            ACCBLOCK_INVOKE(obj, downloadSuccess);
        }];
        
        [self.completionArray removeAllObjects];
        self.isRequestOnAir = NO;
    };
    
    NSString *emojiPanel = AWEInformationStickeEmojiPanelName;
    NSString *category = self.emojiCategoryEffects.categoryKey ?: @"all";
    
    self.isRequestOnAir = YES;
    
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    void (^requestCompletion)(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) = ^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
        
        BOOL success = !error && response.categoryEffects.effects.count > 0;
        [self.logger logPannelUpdateFinished:emojiPanel needUpdate:YES updateDuration:CFAbsoluteTimeGetCurrent() - startTime success:success error:error];

        if (success) {
            [self updateEmojiPagingInfoWithResponse:response isLoadMore:YES];
            ACCBLOCK_INVOKE(completionWrapper, YES);
        } else {
            ACCBLOCK_INVOKE(completionWrapper, NO);
        }
    };
    
    IESEffectPlatformNewResponseModel *response = [EffectPlatform cachedEffectsOfPanel:emojiPanel category:category cursor:self.emojiCursor sortingPosition:self.emojiSortingPosition];
    if (response.categoryEffects.effects.count) {
        ACCBLOCK_INVOKE(requestCompletion, nil, response);
    } else {
       [EffectPlatform downloadEffectListWithPanel:emojiPanel category:category pageCount:AWEInformationStickeEmojiPageCount cursor:self.emojiCursor sortingPosition:self.emojiSortingPosition effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:requestCompletion];
    }
}

- (void)autoLoadCachedEmojis
{
    NSString *emojiPanel = AWEInformationStickeEmojiPanelName;
    NSString *category = self.emojiCategoryEffects.categoryKey ?: @"all";
    IESEffectPlatformNewResponseModel *response = [EffectPlatform cachedEffectsOfPanel:emojiPanel category:category cursor:self.emojiCursor sortingPosition:self.emojiSortingPosition];
    while (response && [response.categoryEffects.effects count] > 0) {
        [self updateEmojiPagingInfoWithResponse:response isLoadMore:YES];
        response = [EffectPlatform cachedEffectsOfPanel:emojiPanel category:category cursor:self.emojiCursor sortingPosition:self.emojiSortingPosition];
    }
}

- (void)updateEmojiPagingInfoWithResponse:(IESEffectPlatformNewResponseModel *)response isLoadMore:(BOOL)isLoadmore
{
    self.emojiCategoryEffects = [response.categoryEffects copy];
    self.emojiCursor = response.categoryEffects.cursor;
    self.emojiHasMore = response.categoryEffects.hasMore;
    self.emojiSortingPosition = response.categoryEffects.sortingPosition;
    self.requestID = response.recId;
    if (isLoadmore) {
        [self.emojiTmpEffects addObjectsFromArray:response.categoryEffects.effects];
        self.emojiEffects = self.emojiTmpEffects;
    } else {
        self.emojiTmpEffects = [response.categoryEffects.effects mutableCopy];
        self.emojiEffects = [response.categoryEffects.effects copy];
    }
}

@end
