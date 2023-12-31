//
//  AWEEditActionContainerView.h
//  Pods
//
//  Created by resober on 2019/5/8.
//

#import <UIKit/UIKit.h>
#import "AWEEditAndPublishViewData+Business.h"
#import <CreativeKit/AWEEditActionItemView.h>
#import "AWEEditActionContainerViewLayout.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^AWEEditActionContainerViewMoreButtonClickedBlock)(void);
@interface AWEEditActionContainerView : UIScrollView
@property (nonatomic, copy, readonly) NSArray<AWEEditAndPublishViewData *> *itemDatas; ///< 用于生成底部操作视图的元数据
@property (nonatomic, copy, readonly) NSArray<AWEEditActionItemView *> *itemViews;
@property (nonatomic, readonly) AWEEditActionContainerViewLayout *containerViewLayout;
- (instancetype)initWithItemDatas:(NSArray<AWEEditAndPublishViewData *> *)itemDatas containerViewLayout:(AWEEditActionContainerViewLayout *)containerViewLayout NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (CGSize)itemSizeWithItem:(AWEEditActionItemView *)item;
- (CGSize)intrinsicContentSizeForItemsInRange:(NSRange)range;
- (AWEEditActionItemView *)findItemViewById:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
