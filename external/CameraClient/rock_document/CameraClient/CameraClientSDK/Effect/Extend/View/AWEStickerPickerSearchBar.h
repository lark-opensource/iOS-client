//
//  AWEStickerPickerSearchBar.h
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/5/31.
//

#import <UIKit/UIKit.h>

@class AWEStickerPickerSearchBar;

typedef NS_ENUM(NSUInteger, AWEStickerPickerSearchBarType) {
    AWEStickerPickerSearchBarTypeRightButtonAuto,
    AWEStickerPickerSearchBarTypeRightButtonShow,
    AWEStickerPickerSearchBarTypeRightButtonHidden,
};

NS_ASSUME_NONNULL_BEGIN

@protocol AWEStickerPickerSearchBarDelegate <UITextFieldDelegate>

@optional

- (void)searchBar:(AWEStickerPickerSearchBar *)searchBar textDidChange:(NSString *)searchText;

@end

@interface AWEStickerPickerSearchBar : UIView

@property (nonatomic, assign) AWEStickerPickerSearchBarType type;
@property (nonatomic, strong, readonly) UITextField *textField;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, weak) id<AWEStickerPickerSearchBarDelegate> delegate;

@property (nonatomic, copy) NSString *placeHolder;
@property (nonatomic, copy) NSAttributedString *attributedPlaceHolder;

@property (nonatomic, strong, nullable) NSString *text;

@property (nonatomic, strong, null_resettable) UIColor *textColor;
@property (nonatomic, strong, null_resettable) UIColor *searchTintColor;

@property (nonatomic, copy, nullable) NSString *rightButtonTitle;

@property (nonatomic, copy, nullable) void(^rightButtonClickedBlock)(void);
@property (nonatomic, copy, nullable) void(^clearButtonClickedBlock)(void);
@property (nonatomic, copy, nullable) void(^didTapTextFieldBlock)(void);

@property (nonatomic, assign) BOOL shouldShowRightButton;
@property (nonatomic, assign) BOOL isHiddenRightButton;
@property (nonatomic, assign) BOOL isTab;

- (void)animatedShowCancelButton:(BOOL)show;
- (void)clearSearchBar;

@end

NS_ASSUME_NONNULL_END
