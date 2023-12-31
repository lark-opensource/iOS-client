//
//  AWEEditRightTopActionContainerViewProtocol.h
//  Pods
//
//  Created by 赖霄冰 on 2019/7/8.
//

#import <Foundation/Foundation.h>
#import "AWEEditActionContainerView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AWEEditRightTopActionContainerViewProtocol <NSObject>

@property (nonatomic, assign) BOOL folded;
@property (nonatomic, copy, readonly) NSArray<AWEEditAndPublishViewData *> *itemDatas; ///< 用于生成底部操作视图的元数据
@property (nonatomic, copy, readonly) NSArray<AWEEditActionItemView *> *itemViews;
@property (nonatomic, strong, readonly) AWEEditActionContainerViewLayout *containerViewLayout;
@property (nonatomic, copy) void(^moreButtonClickedBlock)(void); ///< 当更多被点击时调用的回调
@property (nonatomic, strong) NSNumber *maxHeightValue;
@property (nonatomic, strong, nullable, readonly) AWEEditActionItemView *moreItemView;

- (instancetype)initWithItemDatas:(NSArray<AWEEditAndPublishViewData *> *)itemDatas containerViewLayout:(AWEEditActionContainerViewLayout *)containerViewLayout isFromIM:(BOOL)isFromIM ignoreUnfoldLimitCount:(NSInteger)ignoreUnfoldLimitCount isFromCommerce:(BOOL)isFromCommerce;

- (void)tapToDismiss;

@end

NS_ASSUME_NONNULL_END
