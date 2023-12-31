//
//  ACCMusicCommonSearchBarProtocol.h
//  AWEStudio-Pods-Aweme
//
//  Created by Zhihao Zhang on 2021/2/22.
//

#import <Foundation/Foundation.h>

#import "ACCMusicEnumDefines.h"


NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicCommonSearchBarProtocol <NSObject>

@property (nonatomic, assign) ACCMusicCommonSearchBarType type;
@property (nonatomic, strong, readonly) UITextField *textField;
@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic, strong, nullable) NSString *text;
@property (nonatomic, copy) NSAttributedString *attributedPlaceHolder;
@property (nonatomic, strong, null_resettable) UIColor *textColor;
@property (nonatomic, strong, null_resettable) UIColor *searchFiledBackgroundColor;
@property (nonatomic, strong) UIColor *searchTintColor;
@property (nonatomic, strong, nullable) UIImage *clearImage;
@property (nonatomic, strong, nullable) UIImage *lensImage;
@property (nonatomic, copy, nullable) void(^rightButtonClickedBlock)(void);
@property (nonatomic, copy) void(^searchBarTextChangeBlock)(NSString *barText, NSString *searchText);
@property (nonatomic, copy) void(^textFieldBeginEditingBlock)(void);
@property (nonatomic, copy) void(^textFieldDidEndEditingBlock)(void);
@property (nonatomic, copy) void(^textFieldShouldReturnBlock)(void);

- (void)textFieldBecomeFirstResponder;
- (void)animatedShowCancelButton:(BOOL)show;

- (UIView *)targetSearchBar;


@end

NS_ASSUME_NONNULL_END
