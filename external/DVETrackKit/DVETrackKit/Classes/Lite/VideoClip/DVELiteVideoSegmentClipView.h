//
//   DVELiteVideoSegmentClipView.h
//   DVETrackKit
//
//   Created  by ByteDance on 2022/1/19.
//   Copyright © 2022 ByteDance Ltd. All rights reserved.
//
    

#import <UIKit/UIKit.h>
#import "DVEMediaContext.h"
#import "DVESegmentClipView.h"
#import "DVEVideoTrackViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVELiteVideoSegmentClipView : UIView

/// 缩略图宽高比，默认9:16
@property (nonatomic, assign) CGFloat itemAspectRatio;
/// 视频轨viewmodel
@property (nonatomic, strong) DVEVideoTrackViewModel *viewModel;
/// 隐藏/显示选取区域组件
@property (nonatomic, assign) BOOL clipViewHidden;
/// 选取区域组件透明度
@property (nonatomic, assign) CGFloat clipViewAlpha;

- (instancetype)initWithContext:(DVEMediaContext*)context;

/// 区域选取遮罩
- (DVESegmentClipView *)segmentClipView;

/// 目前选择区域
- (CGRect)selectRect;

/// 区域总长度
- (CGFloat)contentWidth;

/// 刷新缩略图
/// @param force 强制刷新
- (void)reloadDataWithForce:(BOOL)force;


/// 刷新选中区域位置
/// @param left 左侧
/// @param width 宽度
- (void)updateVisablePosition:(CGFloat)left width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
