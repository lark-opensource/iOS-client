//
//  AWEStickerPickerDataContainer.m
//  Indexer
//
//  Created by Fengfanhua.byte on 2021/9/28.
//

#import "AWEStickerPickerDataContainer.h"
#import "ACCConfigKeyDefines.h"
#import "AWEDouyinStickerCategoryModel.h"

#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <EffectPlatformSDK/EffectPlatform.h>

@interface AWEStickerPickerDataContainer ()

@property (nonatomic, assign, readwrite) BOOL loading;

@end

@implementation AWEStickerPickerDataContainer

- (instancetype)init
{
    self = [super init];
    if (self) {
        _identifier = @"default";
        _effectArrayMap = [[NSMutableDictionary alloc] init];
        _enableSearch = YES;
        _effectListUseCache = YES;
    }
    return self;
}

- (void)setFavoriteEffectArray:(NSArray<IESEffectModel *> *)favoriteEffectArray
{
    _favoriteEffectArray = [favoriteEffectArray copy];
}

- (void)fetchCategoryListForPanelName:(NSString *)panelName
                    completionHandler:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completionHandler
{
    self.loading = YES;
    
    @weakify(self);
    [EffectPlatform checkPanelUpdateWithPanel:panelName effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        if (self) {
            [self onCategoriesCheckUpdateCallback:needUpdate panelName:panelName completionHandler:completionHandler];
        } else {
            AWELogToolWarn(AWELogToolTagNone, @"data source has dealloc when fetch categories callback");
            dispatch_async(dispatch_get_main_queue(), ^{
                ACCBLOCK_INVOKE(completionHandler, nil, nil);
            });
        }
    }];
}

- (void)onCategoriesCheckUpdateCallback:(BOOL)needUpdate
                              panelName:(NSString *)panelName
                      completionHandler:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completionHandler
{
    dispatch_async(self.dataHanleQueue, ^{
        IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedCategoriesOfPanel:panelName];
        BOOL hasValidCache = cachedResponse.categories.count > 0;
        if (!needUpdate && hasValidCache) {
            self.loading = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandler) {
                    completionHandler(nil, cachedResponse);
                }
            });
        } else {
            @weakify(self);
            [EffectPlatform fetchCategoriesListWithPanel:panelName
                            isLoadDefaultCategoryEffects:YES
                                         defaultCategory:@""
                                               pageCount:0
                                                  cursor:0
                                               saveCache:YES
                                    effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                              completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
                @strongify(self);
                self.loading = NO;
                if (self) {
                    dispatch_async(self.dataHanleQueue, ^{
                        if (error) {
                            AWELogToolError(AWELogToolTagNone, @"data source fetch category failed, error=%@", error);
                        }
                        if (completionHandler) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                completionHandler(error, response);
                            });
                        }
                    });
                } else {
                    if (completionHandler) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completionHandler(error, nil);
                        });
                    }
                }
            }];
        }
    });
}

@end
