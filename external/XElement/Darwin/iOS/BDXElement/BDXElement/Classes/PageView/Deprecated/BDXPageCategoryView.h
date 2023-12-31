//
//  BDXPageCategoryView.h
//  BDXElement
//
//  Created by AKing on 2020/9/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width

extern CGFloat const BDXPageCategoryViewDefaultHeight;

typedef NS_ENUM(NSUInteger, BDXPageCategoryViewAlignment) {
    BDXPageCategoryViewAlignmentLeft,
    BDXPageCategoryViewAlignmentCenter,
    BDXPageCategoryViewAlignmentRight
};

@protocol BDXPageCategoryViewDelegate <NSObject>
@optional
- (void)categoryViewDidSelectedItemAtIndex:(NSInteger)index;
- (BOOL)categoryViewOtherScrollViewStopScroll;
- (void)categoryViewDidChangeSelectIndex:(NSInteger)index;
@end

@interface BDXPageCategoryView : UIView

@property (nonatomic, weak) id<BDXPageCategoryViewDelegate> delegate;

@property (nonatomic, copy) NSArray<NSString *> *titles;

@property (nonatomic, readonly) CGFloat tagsOriginTotalWidth;

@property (nonatomic, readonly) CGFloat tagsOffsetToCenter;

/// default：0
@property (nonatomic) NSUInteger originalIndex;

/// default：originalIndex
@property (nonatomic, readonly) NSUInteger selectedIndex;

@property (nonatomic) CGFloat height;

@property (nonatomic) BDXPageCategoryViewAlignment alignment;

/// default size：16
@property (nonatomic, strong) UIFont *titleNomalFont;

/// default size：16
@property (nonatomic, strong) UIFont *titleSelectedFont;

/// default：[UIColor grayColor]
@property (nonatomic, strong) UIColor *titleNormalColor;

/// default：[UIColor redColor]
@property (nonatomic, strong) UIColor *titleSelectedColor;

@property (nonatomic) BOOL isBottomBorderHide;

@property (nonatomic) CGFloat bottomBorderWidth;

@property (nonatomic) CGFloat bottomBorderHeight;

@property (nonatomic) CGFloat bottomBorderMarginBottom;

@property (nonatomic, strong) UIColor *bottomBorderColor;

@property (nonatomic, strong, readonly) UIView *topBorder;

@property (nonatomic, strong, readonly) UIView *bottomBorder;

@property (nonatomic, strong, readonly) UIView *vernier;

@property (nonatomic) CGFloat vernierWidth;

/// default：1.8
@property (nonatomic) CGFloat vernierHeight;

@property (nonatomic) UIColor *vernierColor;

/// default: NO
@property (nonatomic) BOOL isVernierHide;

/// default：9
@property (nonatomic) CGFloat itemSpacing;

@property (nonatomic) CGFloat itemWidth;

@property (nonatomic) UIEdgeInsets collectionInset;

/// default：NO
@property (nonatomic) CGFloat isEqualParts;

/// default：0.1
@property (nonatomic) CGFloat animateDuration;


typedef NS_ENUM(NSInteger, LayoutGravity) {
    Center,
    Left
};
@property (nonatomic) LayoutGravity tabLayoutGravity;

typedef NS_ENUM(NSInteger, BoldMode) {
    Selected = 0b01,
    Unselected = 0b10,
    All = 0b11
};
@property (nonatomic) BoldMode tabBoldMode;

- (void)scrollToTargetIndex:(NSUInteger)targetIndex sourceIndex:(NSUInteger)sourceIndex percent:(CGFloat)percent;

- (void)layoutAndScrollToSelectedItem;

- (void)resetTo0State;

- (BOOL)directSetSelectedIndex:(NSInteger)index;
@end

NS_ASSUME_NONNULL_END

