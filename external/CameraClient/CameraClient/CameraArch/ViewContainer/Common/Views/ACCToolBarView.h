//
//  ACCToolBarView.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/27.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCBarItem.h>
#import "ACCBarItem+Adapter.h"
#import "ACCToolBarItemView.h"
#import "ACCToolBarCommonViewLayout.h"
#import "ACCToolBarScrollStackView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCToolBarView : UIView

// use in subclasses, don't use these properties and functions directly
@property (nonatomic, strong) ACCToolBarScrollStackView *scrollStackView;
@property (nonatomic, strong) ACCToolBarItemView *moreButtonView;
@property (nonatomic, strong) ACCToolBarCommonViewLayout *layout;
@property (nonatomic, copy, readonly) NSArray *viewsArray; // stackView arranged subviews
@property (nonatomic, assign, readonly) BOOL folded;
- (void)layoutMoreButtonView;
- (void)layoutUIWithFolded:(BOOL)folded;
- (void)onMoreButtonClicked;
- (NSUInteger) numberOfAllItems;
- (void)clickedBarItemType:(ACCBarItemFunctionType)type;
- (CGFloat)calculateScrollStackViewFrameHeight;

// use properties and functions below
@property (nonatomic, copy) void (^clickItemBlock)(UIView *clickItemView);
@property (nonatomic, copy) void (^clickMoreBlock)(BOOL folded);
@property (nonatomic, assign) BOOL isEdit;
- (instancetype)initWithLayout:(ACCToolBarCommonViewLayout *)layout itemsData:(NSArray<ACCBarItem *> *)items ordersArray:(NSArray *)ordersArray redPointArray:(NSArray *)redPointArray forceInsertArray:(NSArray *)forceInsertArray isEdit:(BOOL)isEdit;
- (void) setupUI;
- (nullable id<ACCBarItemCustomView>) viewWithBarItemID:(nonnull void *)itemId;
- (void) forceInsertWithBarItemIdsArray:(NSArray<NSValue *> *)ids;
- (void) insertItem:(ACCBarItem *)item;
- (void) removeItem:(ACCBarItem *)item;
- (void) hideAllLabelWithSeconds:(double)seconds;
- (void) showAllLabel;
- (void) hideAllLabel;
- (void) resetUI;
- (void) resetFoldState;
- (void) resetFoldStateAndShowLabel;
- (void) resetShrinkState;

@end

NS_ASSUME_NONNULL_END
