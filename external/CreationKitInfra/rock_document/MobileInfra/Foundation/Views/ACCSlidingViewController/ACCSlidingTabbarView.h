//
//  ACCSlidingTabbarView.h
//  CameraClient
//
//  Created by gongyanyun  on 2018/6/22.
//

#import <UIKit/UIKit.h>
#import "ACCSlidingTabbarProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCSlidingTabButtonStyle) {
    ACCSlidingTabButtonStyleText = 0,
    ACCSlidingTabButtonStyleIcon,
    ACCSlidingTabButtonStyleIconAndText,
    ACCSlidingTabButtonStyleOriginText,
    ACCSlidingTabButtonStyleImageAndTitle,
    ACCSlidingTabButtonStyleTextAndLineEqualLength,
};

@interface ACCSlidingTabButton : UIButton

- (void)showDot:(BOOL)show color:(nullable UIColor *)color;

@end

typedef void(^ACCSlidingTabbarViewDidEndDeceleratingBlock)(NSInteger startIndex, NSInteger count);

@interface ACCSlidingTabbarView : UIView<ACCSlidingTabbarProtocol>

@property (nonatomic, assign) BOOL shouldShowTopLine;
@property (nonatomic, assign) BOOL shouldShowBottomLine;
@property (nonatomic, assign) BOOL shouldShowSelectionLine;
@property (nonatomic, assign) BOOL shouldShowButtonSeperationLine;
@property (nonatomic, strong) UIColor *selectionLineColor;
@property (nonatomic, strong) UIColor *topBottomLineColor;
@property (nonatomic, assign) BOOL shouldUpdateSelectButtonLine;

@property (nonatomic, assign) CGSize selectionLineSize;
@property (nonatomic, assign) CGFloat selectionLineCornerRadius;
@property (nonatomic, assign) BOOL enableSwitchAnimation; // default is NO
@property (nonatomic, assign) UIEdgeInsets contentInset;

@property (nonatomic, assign) BOOL needOptimizeTrackPointForVisibleRect;

@property (nonatomic, copy) ACCSlidingTabbarViewDidEndDeceleratingBlock didEndDeceleratingBlock;


- (instancetype)initWithFrame:(CGRect)frame buttonStyle:(ACCSlidingTabButtonStyle)buttonStyle;

- (instancetype)initWithFrame:(CGRect)frame buttonStyle:(ACCSlidingTabButtonStyle)buttonStyle dataArray:(nullable NSArray<NSString *> *)dataArray selectedDataArray:(nullable NSArray<NSString *> *)selectedDataArray;

- (void)configureText:(nullable NSString *)text image:(nullable UIImage *)image selectedText:(nullable NSString *)selectedText selectedImage:(nullable UIImage *)selectedImage index:(NSInteger)index;
- (void)resetDataArray:(nullable NSArray *)dataArray selectedDataArray:(nullable NSArray *)selectedDataArray;
- (void)insertSeparatorArrowAndTitle:(nullable NSString *)titleString forImageStyleAtIndex:(NSInteger)index;
- (void)replaceButtonImage:(nullable UIImage *)image atIndex:(NSInteger)index;
- (void)replaceButtonImgae:(nullable UIImage *)image title:(nullable NSString *)titleString atIndex:(NSInteger)index;
- (void)insertAtFrontWithButtonImage:(nullable UIImage *)image;
- (void)insertAtFrontWithButtonImage:(nullable UIImage *)image title:(nullable NSString *)titleString;
- (void)configureButtonTextColor:(nullable UIColor *)color selectedTextColor:(nullable UIColor *)selectedColor;
- (void)configureButtonTextFont:(nullable UIFont *)font hasShadow:(BOOL)hasShadow;
- (void)configureButtonTextFont:(nullable UIFont *)font selectedFont:(nullable UIFont *)selectedFont;
- (void)configureTitlePadding:(CGFloat)padding;
- (void)configureTitlePadding:(CGFloat)padding buttonStyle:(ACCSlidingTabButtonStyle)buttonStyle;
- (void)configureTitleMinLength:(CGFloat)titleMinLength;
- (void)showButtonDot:(BOOL)show index:(NSInteger)index color:(nullable UIColor *)color;
- (BOOL)isButtonDotShownOnIndex:(NSInteger)index;

- (void)setTopLineColor:(nullable UIColor *)color;
- (void)setBottomLineColor:(nullable UIColor *)color;
- (void)setTopBottomLineColor:(nullable UIColor *)topBottomLineColor;

@end

NS_ASSUME_NONNULL_END
