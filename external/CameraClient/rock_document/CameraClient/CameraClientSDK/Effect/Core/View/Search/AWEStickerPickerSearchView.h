//
//  AWEStickerPickerSearchView.h
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/5/17.
//

#import <Foundation/Foundation.h>

#import "AWEStickerCategoryModel.h"
#import "AWEStickerPickerModel.h"
#import "AWEStickerPickerModel+Search.h"
#import "AWEStickerPickerUIConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWEStickerPickerSearchView : UIView

@property (nonatomic, strong, readonly) UITextField *textField;

@property (nonatomic, strong) AWEStickerPickerModel *model;

@property (nonatomic, strong, nullable) AWEStickerCategoryModel *categoryModel;

@property (nonatomic, assign) AWEStickerPickerSearchViewHideKeyboardSource source;

- (instancetype)initWithIsTab:(BOOL)isTab;

- (void)updateUIConfig:(id<AWEStickerPickerUIConfigurationProtocol>)config;

- (void)updateSearchSource:(AWEStickerPickerSearchViewHideKeyboardSource)source;

- (void)updateSearchText:(NSString * _Nullable)searchText;

- (void)updateCategoryModel:(AWEStickerCategoryModel * _Nullable)categoryModel isUseHot:(BOOL)isHotCategory;

- (void)updateSelectedStickerForId:(NSString *)identifier;

- (void)enableCollectionViewToScroll:(BOOL)enabled;

- (void)updateSubviewsAlpha:(CGFloat)alpha;

- (void)textFieldBecomeFirstResponder;

- (void)textFieldResignFirstResponder;

- (void)trackRecommendedListDidShow;

- (void)showLoadingView:(BOOL)show;

- (void)triggerKeyboardToHide;

- (void)onClearBGClicked;

@end

NS_ASSUME_NONNULL_END
