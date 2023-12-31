//
//  DVEMultipleTrackViewProtocol.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/23.
//

#import <Foundation/Foundation.h>
#import "DVETrackUIModel.h"
#import "DVEMultipleTrackViewCellViewModel.h"
#import "DVEMultipleTrackViewCell.h"
#import "DVEMultipleTrackView.h"
#import "DVESegmentClipView.h"

NS_ASSUME_NONNULL_BEGIN

@class DVEMultipleTrackView;
// 多轨道数据源
@protocol DVEMultipleTrackViewDataSource <NSObject>

// 轨道的原始信息
- (NSArray<DVETrackUIModel *> *)draftTracks;

// 轨道行数
- (NSInteger)numberOfSections;

// 对应轨道的列数
- (NSInteger)numberOfItemsInSection:(NSInteger)section;

// 对应indexPath的数据源
- (DVEMultipleTrackViewCellViewModel * _Nullable)itemViewModelAtIndexPath:(NSIndexPath *)indexPath;

/// 最大的轨道数目
- (NSInteger)maxTrackCount;

/// 注册的cell
- (Class)registerCellClass;

/// cell的唯一标识
- (NSString *)registerCellIdentifier;

// 创建新的cell
- (DVEMultipleTrackViewCell *)buildCell;

// cell高度
- (CGFloat)cellHeight;

// 通过草稿构建片段viewModel
- (DVEMultipleTrackViewCellViewModel * _Nullable)buildCellViewModelFromNode:(NLETimeSpaceNode_OC *)timeSpaceNode
                                                                      frame:(CGRect)frame;

// 通过草稿更新片段viewModel
- (void)updateCellViewModel:(DVEMultipleTrackViewCellViewModel *)cellViewModel
              timeSpaceNode:(NLETimeSpaceNode_OC *)node
                      frame:(CGRect)frame;

// 当前选中片段
- (NLETimeSpaceNode_OC *)selectSegment;

// 片段所在的位置（视频副轨特别处理）
- (NSIndexPath * _Nullable)targetIndexPathOfSlotId:(NSString *)nodeId;

// 注册Cell
- (void)registerCellInTrackView:(DVEMultipleTrackView *)trackView;
@end



#pragma mark - 多轨道点击协议

@protocol DVEMultipleTrackViewClickDelegate <NSObject>

/// 单击选中
- (void)trackView:(DVEMultipleTrackView *)trackView didSelectItemAtIndexPath:(NSIndexPath *)indexPath cellViewModel:(DVEMultipleTrackViewCellViewModel *)cellViewModel;

/// 取消选中
- (void)trackView:(DVEMultipleTrackView *)trackView didDeSelectItemAtIndexPath:(NSIndexPath *)indexPath cellViewModel:(DVEMultipleTrackViewCellViewModel *)cellViewModel;

/// 双击选中
- (void)trackView:(DVEMultipleTrackView *)trackView didDoubleClickItemAtIndexPath:(NSIndexPath *)indexPath cellViewModel:(DVEMultipleTrackViewCellViewModel *)cellViewModel;

/// 选中片段是否需要滚动到对应位置
- (BOOL)trackViewShouldScrollAfterSelect;


@end

/// 多轨道尾部插入
@protocol DVEMultipleTrackTailInsertProtocol <NSObject>

/// 尾部插入提示背景颜色
- (UIColor * _Nullable)trackViewTailInsertTipBackgroundColorOf:(DVEMultipleTrackViewCellViewModel * _Nullable)cellViewModel;

@end


/// 多轨道长按拖动协议

@protocol DVEMultipleTrackMoveProtocol <NSObject>

/// 最长可移动的长度限制
- (CGFloat)trackViewMoveMaxX;

/// 拖动
- (void)trackView:(DVEMultipleTrackView *)trackView didMoveChanged:(DVEMultipleTrackViewCellViewModel *)cellViewModel startRect:(CGRect)startRect toRect:(CGRect)toRect hasNoIntersection:(BOOL)hasNoIntersection;

/// 结束拖动
- (void)trackView:(DVEMultipleTrackView *)trackView didMoveEnded:(DVEMultipleTrackViewCellViewModel *)cellViewModel startRect:(CGRect)startRect toRect:(CGRect)toRect;

@end


/// 多轨道裁剪协议

@protocol DVEMultipleTrackClipProtocol <NSObject>

/// 开始裁剪
- (void)trackView:(DVEMultipleTrackView *)trackView didClipBegan:(DVESegmentClipViewPanPosition)position cellViewModel:(DVEMultipleTrackViewCellViewModel *)cellViewModel;

/// 裁剪中
- (void)trackView:(DVEMultipleTrackView *)trackView didClipChanged:(DVESegmentClipViewPanPosition)position cellViewModel:(DVEMultipleTrackViewCellViewModel *)cellViewModel startRect:(CGRect)startRect toRect:(CGRect)toRect;

/// 可允许裁剪的区域
- (CGRect)trackView:(DVEMultipleTrackView *)trackView shouldClipChangedRect:(DVESegmentClipViewPanPosition)position cellViewModel:(DVEMultipleTrackViewCellViewModel *)cellViewModel startRect:(CGRect)startRect toRect:(CGRect)toRect;

/// 结束裁剪
- (void)trackView:(DVEMultipleTrackView *)trackView didClipEnded:(DVESegmentClipViewPanPosition)position cellViewModel:(DVEMultipleTrackViewCellViewModel *)cellViewModel startRect:(CGRect)startRect toRect:(CGRect)toRect;

@end


NS_ASSUME_NONNULL_END
