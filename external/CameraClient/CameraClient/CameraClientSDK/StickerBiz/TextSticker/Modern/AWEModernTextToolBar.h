//
//  AWEModernTextToolBar.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/3/16.
//

#import <UIKit/UIKit.h>
#import "AWETextToolStackView.h"
#import <CameraClientModel/ACCTextRecommendModel.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEStoryFontModel, AWEStoryColor, ACCTextStickerRecommendItem;

@interface AWEModernTextToolBar : UIView <AWETextToolStackViewProtocol>

AWETextStcikerViewUsingCustomerInitOnly;

- (instancetype)initWithFrame:(CGRect)frame barItemIdentityList:(NSArray<AWETextStackViewItemIdentity > *)itemIdentityList NS_DESIGNATED_INITIALIZER;
- (void)configRecommendStyle:(AWEModernTextRecommendMode)mode;
#pragma mark - text recommend
- (void)updateWithRecommendTitles:(NSArray<ACCTextStickerRecommendItem *> *)titles;

#pragma mark - color
@property (nonatomic, assign, readonly) BOOL isShowingColorView;

- (void)updateColorViewShowStatus:(BOOL)shouldShow;

@property (nonatomic, copy) void(^didSelectedCloseColorViewBtnBlock)(void);

@property (nonatomic, copy) void(^didSelectedColorBlock) (AWEStoryColor *selectColor, NSIndexPath *indexPath);

@property (nonatomic, strong, readonly) AWEStoryColor *selectedColor;

- (void)selectWithColor:(UIColor *)color;

#pragma mark - font
@property (nonatomic, copy) void(^didSelectedFontBlock) (AWEStoryFontModel *selectFont, NSIndexPath *indexPath);

@property (nonatomic, strong, readonly) AWEStoryFontModel *selectedFont;

@property (nonatomic, copy) void(^didSelectedTitleBlock) (NSString *title);
@property (nonatomic, copy) void(^didExposureTitleBlock) (NSString *title);
@property (nonatomic, copy) dispatch_block_t didCallTitleLibBlock;

- (void)selectWithFontId:(NSString *_Nullable)fontId;

+ (CGFloat)barHeight:(AWEModernTextRecommendMode)style;

@end

NS_ASSUME_NONNULL_END
