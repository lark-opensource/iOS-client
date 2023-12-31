//
//  AWEStickerPickerModel+Search.m
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/5/29.
//

#import "AWEStickerPickerModel+Search.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <EffectPlatformSDK/EffectPlatform+Search.h>

@implementation AWEStickerPickerModel (Search)

- (BOOL)isStickerSelected:(IESEffectModel *)sticker
{
    return [self.currentSticker.effectIdentifier isEqualToString:sticker.effectIdentifier];
}

- (void)willDisplaySticker:(IESEffectModel *)sticker indexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:willDisplaySticker:indexPath:)]) {
        [self.delegate stickerPickerModel:self willDisplaySticker:sticker indexPath:indexPath];
    }
}

- (void)didSelectSticker:(IESEffectModel *)sticker category:(AWEStickerCategoryModel *)category indexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:didSelectSticker:category:indexPath:)]) {
        [self.delegate stickerPickerModel:self didSelectSticker:sticker category:category indexPath:indexPath];
    }

    [self insertStickersAtHotTab:@[sticker]];
}

- (void)didTapHashtag:(NSString *)hashtag
{
    // tap on hashtag is same as user inputs query
    // so need to trigger a change in textfield
    self.searchText = hashtag;
    self.isFromHashtag = YES;
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:didTapHashtag:)]) {
        [self.delegate stickerPickerModel:self didTapHashtag:hashtag];
    }
}

- (void)fetchHashtagsListWithIsTextFieldFirstResponder:(BOOL)isFirstResponder
{
    CFTimeInterval showloadingStartTime = CACurrentMediaTime();

    @weakify(self);
    [[EffectPlatform sharedInstance] fetchSearchRecommendWordsWithPanel:self.panelName
                                                               category:@""
                                                        extraParameters:@{}
                                                             completion:^(NSError * _Nullable error, NSString * _Nullable searchTips, NSArray<NSString *> * _Nullable recommendWords) {
        @strongify(self);
        [self handleHashtagsResponseWithError:error
                                   searchTips:searchTips
                               recommendWords:recommendWords
                             isFirstResponder:isFirstResponder
                                    startTime:showloadingStartTime];
    }];
}

- (void)searchTextDidChange:(NSString *)searchText isTab:(BOOL)isTab
{
    self.searchText = searchText;

    /**
     If the change happens in search view, then fetch data from effect data source
     */

    self.isCompleted = NO;

    // if the duration of loading the search effects is more than 500ms, then need to show loadingView
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(stickerPickerModel:willDisplayLoadingView:)]) {
            [self.delegate stickerPickerModel:self willDisplayLoadingView:!self.isCompleted];
        }
    });

    CFTimeInterval showloadingStartTime = CACurrentMediaTime();

    if (!searchText || [searchText isEqualToString:@""]) {
        [self handleResponseWithError:nil searchEffectsModel:nil startTime:showloadingStartTime];
        return;
    }

    @weakify(self);
    [[EffectPlatform sharedInstance] fetchSearchEffectsWithKeyWord:searchText
                                                          searchID:@"0"
                                                            cursor:0
                                                         pageCount:60
                                                   extraParameters:@{}
                                                        completion:^(NSError * _Nullable error, IESSearchEffectsModel * _Nullable searchEffectsModel) {
        @strongify(self);

        [self handleResponseWithError:error searchEffectsModel:searchEffectsModel startTime:showloadingStartTime];

        BOOL isUseHot = NO;
        NSString *searchID = @"";

        // Track "prop_search" event
        if (searchEffectsModel) {
            searchID = searchEffectsModel.searchID;
            isUseHot = searchEffectsModel.isUseHot;
        }

        NSMutableDictionary *params = @{
            @"search_id" : searchID,
            @"enter_method" : self.isFromHashtag ? @"search_rec" : @"search_sug",
            @"search_keyword" : searchText ?: @"",
            @"is_success" : isUseHot ? @(0) : @(1),
            @"duration" : @((CACurrentMediaTime() - showloadingStartTime) * 1000),
            @"previous_page" : @"prop_main_panel",
        }.mutableCopy;

        [self trackWithEventName:@"prop_search" params:params];

        // reset
        self.isFromHashtag = NO;
    }];
}

- (void)handleHashtagsResponseWithError:(NSError * _Nullable)error
                             searchTips:(NSString * _Nullable)searchTips
                         recommendWords:(NSArray<NSString *> * _Nullable)recommendWords
                       isFirstResponder:(BOOL)isFirstResponder
                              startTime:(CFTimeInterval)startTime
{
    NSMutableDictionary *extraParams = [NSMutableDictionary dictionary];
    NSArray<NSString *> *recommendedWordsPlaceholder = @[@"变漫画", @"潜水艇小游戏"];

    if (error) {
        AWELogToolError(AWELogToolTagEffectPlatform, @"fetching recommendation effects is error: %@", error);
        extraParams[@"error_code"] = @(error.code);
        extraParams[@"error_desc"] = error.localizedDescription;
    }

    if (!ACC_isEmptyArray(recommendWords)) {
        recommendedWordsPlaceholder = recommendWords;
    }

    self.recommendationList = recommendedWordsPlaceholder;

    NSInteger status = (error) ? 1 : 0;
    extraParams[@"duration"] = @((CFAbsoluteTimeGetCurrent() - startTime) * 1000);
    extraParams[@"is_placeholder"] = ACC_isEmptyArray(recommendWords) ? @(1) : @(0);
    extraParams[@"recommendation_list_count"] = @(recommendedWordsPlaceholder.count);
    [ACCMonitor() trackService:@"search_prop_recommendation_list_shown_success_rate" status:status extra:extraParams];
}

- (void)handleResponseWithError:(NSError * _Nullable)error
             searchEffectsModel:(IESSearchEffectsModel * _Nullable)searchEffectsModel
                      startTime:(CFTimeInterval)startTime
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:willDisplayLoadingView:)]) {
        [self.delegate stickerPickerModel:self willDisplayLoadingView:NO];
    }

    NSMutableDictionary *extraParams = [NSMutableDictionary dictionary];

    if (error) {
        AWELogToolError(AWELogToolTagEffectPlatform, @"Search effect model is error: %@", error);
        extraParams[@"error_code"] = @(error.code);
        extraParams[@"error_desc"] = error.localizedDescription;
    }

    if (self.isCompleted) {
        return;
    }

    if (searchEffectsModel) {
        self.searchCategoryModel.stickers = [searchEffectsModel.effects copy];
        self.isUseHot = searchEffectsModel.isUseHot;
        self.searchID = searchEffectsModel.searchID;
        self.searchTips = searchEffectsModel.searchTips;
        self.searchMethod = searchEffectsModel.isUseHot ? @"recommend" : @"search";

    } else {
        self.searchCategoryModel.stickers = [NSArray array];
        self.isUseHot = NO;
        self.searchID = @"";
        self.searchTips = @"";
        self.searchMethod = @"";
    }

    NSInteger status = (error) ? 1 : 0;
    extraParams[@"duration"] = @((CFAbsoluteTimeGetCurrent() - startTime) * 1000);
    extraParams[@"is_empty_result"] = searchEffectsModel.isUseHot ? @(1) : @(0);
    extraParams[@"search_id"] = searchEffectsModel.searchID ?: @"";
    extraParams[@"search_method"] = searchEffectsModel.isUseHot ? @"recommend" : @"search";
    [ACCMonitor() trackService:@"search_prop_success_rate" status:status extra:extraParams];

    self.isCompleted = YES;

    if ([self.delegate respondsToSelector:@selector(stickerPickerModelSendSearchCategoryModel:)]) {
        [self.delegate stickerPickerModelSendSearchCategoryModel:self];
    }
}

- (void)shouldTriggerKeyboardToShowIfIsTab:(BOOL)isTab source:(AWEStickerPickerSearchViewHideKeyboardSource)source
{
    // show keyboard in controller
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:triggerKeyboardToShow:)]) {
        [self.delegate stickerPickerModel:self triggerKeyboardToShow:isTab];
    }
}

- (void)shouldTriggerKeyboardToHide:(BOOL)isSearchView source:(AWEStickerPickerSearchViewHideKeyboardSource)source
{
    self.source = source;
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:triggerKeyboardToHide:)]) {
        [self.delegate stickerPickerModel:self triggerKeyboardToHide:isSearchView];
    }
}

- (void)showKeyboardWithNotification:(NSNotification *)notification
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:showKeyboardWithNotification:)]) {
        [self.delegate stickerPickerModel:self showKeyboardWithNotification:notification];
    }
}

- (void)hideKeyboardWithNotification:(NSNotification *)notification source:(AWEStickerPickerSearchViewHideKeyboardSource)source
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:hideKeyboardWithNotification:source:)]) {
        [self.delegate stickerPickerModel:self hideKeyboardWithNotification:notification source:source];
    }
}

- (void)updateSearchPanelToPackUp
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerModelUpdateSearchViewToPackUp:)]) {
        [self.delegate stickerPickerModelUpdateSearchViewToPackUp:self];
    }
}

- (void)trackWithEventName:(NSString *)eventName params:(NSMutableDictionary *)params
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:trackWithEventName:params:)]) {
        [self.delegate stickerPickerModel:self trackWithEventName:eventName params:params];
    }
}

- (void)trackRecommendationListDidShowWithIsFirstResponder:(BOOL)isFirstResponder
{
    [self.recommendationList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *params = @{
            @"words_position": @(idx+1),
            @"word_name": obj,
            @"is_panel_unfold": (isFirstResponder) ? @(1) : @(0)
        }.mutableCopy;

        if ([self.delegate respondsToSelector:@selector(stickerPickerModel:trackWithEventName:params:)]) {
            [self.delegate stickerPickerModel:self trackWithEventName:@"prop_trending_words_show" params:params];
        }
    }];
}

@end
