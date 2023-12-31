//
//  AWEStickerPickerModel+Search.h
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/5/29.
//

#import "AWEStickerPickerModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWEStickerPickerModel (Search)

/**
 @brief Event Tracker
 */
- (void)trackWithEventName:(NSString *)eventName params:(NSMutableDictionary *)params;

- (void)trackRecommendationListDidShowWithIsFirstResponder:(BOOL)isFirstResponder;

/**
 @brief Recommendation Hashtags
 */
- (void)didTapHashtag:(NSString * _Nullable)hashtag;

- (void)fetchHashtagsListWithIsTextFieldFirstResponder:(BOOL)isFirstResponder;

/**
 @brief Search Text
 */
- (void)searchTextDidChange:(NSString * _Nullable)searchText isTab:(BOOL)isTab;

/**
 @brief Search Sticker Results
 */
- (BOOL)isStickerSelected:(IESEffectModel *)sticker;

- (void)willDisplaySticker:(IESEffectModel *)sticker indexPath:(NSIndexPath *)indexPath;

- (void)didSelectSticker:(IESEffectModel *)sticker category:(AWEStickerCategoryModel *)category indexPath:(NSIndexPath *)indexPath;

/**
 @brief Show / Hide Keyboard
 */
- (void)shouldTriggerKeyboardToShowIfIsTab:(BOOL)isTab source:(AWEStickerPickerSearchViewHideKeyboardSource)source;

- (void)shouldTriggerKeyboardToHide:(BOOL)isSearchView source:(AWEStickerPickerSearchViewHideKeyboardSource)source;

- (void)showKeyboardWithNotification:(NSNotification * _Nullable)notification;

- (void)hideKeyboardWithNotification:(NSNotification * _Nullable)notification source:(AWEStickerPickerSearchViewHideKeyboardSource)source;

/**
 @brief search panel animate
 */
- (void)updateSearchPanelToPackUp;

@end

NS_ASSUME_NONNULL_END
