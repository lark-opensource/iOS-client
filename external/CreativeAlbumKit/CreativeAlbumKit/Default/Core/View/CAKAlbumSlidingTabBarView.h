//
//  CAKAlbumSlidingTabBarView.h
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/1.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CAKAlbumSlidingViewController;
typedef NS_ENUM(NSInteger, CAKAlbumSlidingTabButtonStyle) {
    CAKAlbumSlidingTabButtonStyleText = 0,
    CAKAlbumSlidingTabButtonStyleIcon,
    CAKAlbumSlidingTabButtonStyleIconAndText,
    CAKAlbumSlidingTabButtonStyleOriginText, //传统样式.
    CAKAlbumSlidingTabButtonStyleImageAndTitle,
    CAKAlbumSlidingTabButtonStyleTextAndLineEqualLength,  //中间页tabview样式，文字与选中的线等长
};

@interface CAKAlbumSlidingTabButton : UIButton

- (void)showDot:(BOOL)show color:(nullable UIColor *)color;

@end

typedef void(^CAKSlidingTabbarViewDidEndDeceleratingBlock)(NSInteger startIndex, NSInteger count);

@interface CAKAlbumSlidingTabBarView : UIView

@property (nonatomic, weak, nullable) CAKAlbumSlidingViewController *slidingViewController;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) BOOL shouldShowTopLine;
@property (nonatomic, assign) BOOL shouldShowBottomLine;
@property (nonatomic, assign) BOOL shouldShowSelectionLine;
@property (nonatomic, assign) BOOL shouldShowButtonSeperationLine;
@property (nonatomic, strong, nullable) UIColor *selectionLineColor;
@property (nonatomic, strong, nullable) UIColor *topBottomLineColor;
@property (nonatomic, assign) BOOL shouldUpdateSelectButtonLine;

@property (nonatomic, assign) CGSize selectionLineSize;
@property (nonatomic, assign) CGFloat selectionLineCornerRadius;
@property (nonatomic, assign) BOOL enableSwitchAnimation; // default is NO
@property (nonatomic, assign) UIEdgeInsets contentInset;

@property (nonatomic, assign) BOOL needOptimizeTrackPointForVisibleRect;
//needOptimizeTrackPointForVisibleRect设置为YES时，如果在操作结束的时刻，屏幕内的可视区域未发生变化，则不执行didEndDeceleratingBlock
//2tab频道的tabbar在打点的时候，判断如果用户在操作（滑动/点击）结束后，屏幕中展示的tabbar区域未发生变化，则不重复打点；否则重新上报打点；

@property (nonatomic, copy, nullable) CAKSlidingTabbarViewDidEndDeceleratingBlock didEndDeceleratingBlock;


- (void)slidingControllerDidScroll:(UIScrollView * _Nullable)scrollView;
- (void)updateSelectedLineFrame;
- (instancetype _Nonnull)initWithFrame:(CGRect)frame buttonStyle:(CAKAlbumSlidingTabButtonStyle)buttonStyle;
/**
初始化方法

@param frame tabview frame
@param buttonStyle 按钮样式(图片/文字)
@param dataArray 图片名/标题的数组
@param selectedDataArray 选中状态的图片名/标题的数组
@return 初始化后的对象
*/
- (instancetype _Nonnull)initWithFrame:(CGRect)frame buttonStyle:(CAKAlbumSlidingTabButtonStyle)buttonStyle dataArray:(nullable NSArray<NSString *> *)dataArray selectedDataArray:(nullable NSArray<NSString *> *)selectedDataArray;

- (void)configureText:(nullable NSString *)text image:(nullable UIImage *)image selectedText:(nullable NSString *)selectedText selectedImage:(nullable UIImage *)selectedImage index:(NSInteger)index;
- (void)resetDataArray:(nullable NSArray *)dataArray selectedDataArray:(nullable NSArray *)selectedDataArray;
- (void)insertSeparatorArrowAndTitle:(nullable NSString *)titleString forImageStyleAtIndex:(NSInteger)index;//在指定index按钮的后面加一个箭头分割
- (void)replaceButtonImage:(nullable UIImage *)image atIndex:(NSInteger)index;//给指定index按钮更新一个图
- (void)replaceButtonImgae:(nullable UIImage *)image title:(nullable NSString *)titleString atIndex:(NSInteger)index;
- (void)insertAtFrontWithButtonImage:(nullable UIImage *)image;//在第一位插入一个图的按钮
- (void)insertAtFrontWithButtonImage:(nullable UIImage *)image title:(nullable NSString *)titleString;//在第一位插入一个图的按钮
- (void)configureButtonTextColor:(nullable UIColor *)color selectedTextColor:(nullable UIColor *)selectedColor;
- (void)configureButtonTextFont:(nullable UIFont *)font hasShadow:(BOOL)hasShadow;
- (void)configureButtonTextFont:(nullable UIFont *)font selectedFont:(nullable UIFont *)selectedFont;
- (void)configureTitlePadding:(CGFloat)padding;
- (void)configureTitleMinLength:(CGFloat)titleMinLength;
/**
 展示右上角的小圆点
 */
- (void)showButtonDot:(BOOL)show index:(NSInteger)index color:(nullable UIColor *)color;
- (BOOL)isButtonDotShownOnIndex:(NSInteger)index;

- (void)setTopLineColor:(nullable UIColor *)color;
- (void)setBottomLineColor:(nullable UIColor *)color;
- (void)setTopBottomLineColor:(nullable UIColor *)topBottomLineColor;

@end
