//
//  AWEModernStickerSwitchTabView.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/26.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>

extern NSString *const AWEModernStickerSwitchTabViewTabNameCollection;

@class IESCategoryModel, AWEModernStickerSwitchTabView, AWEVideoPublishViewModel;

@protocol AWEModernStickerSwitchTabViewDelegate <NSObject>

- (void)switchTabDidSelectedAtIndex:(NSInteger)index;
/// 返回是否需要拦截当次点击事件
- (BOOL)switchTabWillSelectedAtIndex:(NSInteger)index;
- (AWEVideoPublishViewModel *)switchTabPublishModel;

@optional
- (void)switchTab:(AWEModernStickerSwitchTabView *)switchTab didTapToChangeTabAtIndex:(NSInteger)index;

@end

@interface AWEModernStickerSwitchTabView : UIView

@property (nonatomic, assign) AWEStickerPanelType panelType;
@property (nonatomic, weak) id<AWEModernStickerSwitchTabViewDelegate> delegate;
@property (nonatomic, assign) BOOL shouldIgnoreAnimation;
@property (nonatomic, assign, readonly) NSInteger selectedIndex;
@property (nonatomic, assign, readonly) NSInteger lastSelectedIndex;
@property (nonatomic, assign) CGFloat proportion;
@property (nonatomic, assign) BOOL hasSelectItem;
@property (nonatomic, assign) BOOL isPhotoMode;
@property (nonatomic, assign) BOOL isStoryMode;
@property (nonatomic, strong, readonly) NSArray <IESCategoryModel *> *categories;
@property (nonatomic, copy) NSDictionary <NSString *, NSString *> *trackingInfoDictionary;
@property (nonatomic, copy) NSDictionary <NSString *, NSString *> *schemaTrackParams;


- (void)showYellowDotOnIndex:(NSInteger)index;

- (void)animateFavoriteOnIndex:(NSInteger)index showYellowDot:(BOOL)showYellowDot;

- (instancetype)initWithStickerCategories:(NSArray <IESCategoryModel *> *)categories;

- (void)refreshWithStickerCategories:(NSArray <IESCategoryModel *> *)categories completion:(void (^)(BOOL finished))completion;

- (void)selectItemAtIndex:(NSInteger)index animated:(BOOL)animated;

- (void)trackSelectedStatusWithIndexPath:(NSInteger)indexPath;

- (NSString *)selectedCategoryName;
- (IESCategoryModel *)selectedCategoryIgnoringCollection; /// 当前选中的tab（选中收藏返回nil）

@end
