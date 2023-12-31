//
//   DVELiteDurationClipView.h
//   DVETrackKit
//
//   Created  by ByteDance on 2022/1/21.
//   Copyright © 2022 ByteDance Ltd. All rights reserved.
//
    

#import <UIKit/UIKit.h>
#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@class DVELiteDurationClipView;

@protocol DVELiteDurationClipViewDelegate <NSObject>

- (void)durationClipViewDidChangeTimeRange:(DVELiteDurationClipView *)clipView;

@end

@interface DVELiteDurationClipView : UIView
/// 选择 区域左侧时间
@property (nonatomic, assign) CGFloat startTime;
/// 选择 区域右侧时间
@property (nonatomic, assign) CGFloat endTime;
/// 滑杆宽度 默认3
@property (nonatomic, assign) CGFloat cursorWidth;
/// 滑杆圆角 默认1.5
@property (nonatomic, assign) CGFloat cursorCornerRadius;
/// 缩略图宽高比，默认9:16
@property (nonatomic, assign) CGFloat itemAspectRatio;
/// 隐藏/显示选取区域组件（包括时间展示）
@property (nonatomic, assign) BOOL clipViewHidden;
/// 选取区域组件透明度（包括时间展示）
@property (nonatomic, assign) CGFloat clipViewAlpha;
/// 内部偏移
@property (nonatomic, assign) UIEdgeInsets insets;

@property (nonatomic, weak) id<DVELiteDurationClipViewDelegate> delegate;

- (instancetype)initWithContext:(DVEMediaContext*)context ;
/// 当前播放时间
- (CGFloat)currentTime;

@end

NS_ASSUME_NONNULL_END
