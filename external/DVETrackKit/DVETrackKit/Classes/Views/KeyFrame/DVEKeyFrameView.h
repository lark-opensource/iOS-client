//
//  DVEKeyFrameView.h
//  DVETrackKit
//
//  Created by bytedance on 2021/8/26.
//

#import <UIKit/UIKit.h>
#import "DVEKeyFrameViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVEKeyFrameViewDelegate <NSObject>

- (void)keyFrameItemDidSelect:(NLETrackSlot_OC *)slot keyFrame:(NLETrackSlot_OC *)keyFrame;

@end


@interface DVEKeyFrameView : UIView

@property (nonatomic, strong) DVEKeyFrameViewModel *viewModel;
@property (nonatomic, weak) id<DVEKeyFrameViewDelegate> delegate;

/// 根据DVEKeyFrameViewModel去初始化关键帧UI
/// @param viewModel 关键帧的ViewModel
- (instancetype)initWithViewModel:(DVEKeyFrameViewModel *)viewModel;

/// 显示关键帧
- (void)showKeyFrame;

/// 隐藏关键帧
- (void)hideKeyFrame;
/// 更新关键帧
- (void)updateKeyFrame;

/// 检查时间线是否到达了关键帧
- (void)checkTimeLineWithKeyFrame;

/// 根据限定的leftLimit去更新关键帧，只保留在leftLimit之后的关键帧
/// @param leftLimit 关键帧内部左侧的UI距离限制
- (void)updateKeyFrameWithLeftLimit:(CGFloat) leftLimit;

/// 根据限定的rightLimit去更新关键帧，只保留在rightLimit之前的关键帧
/// @param rightLimit 关键帧内部右侧的UI距离限制
- (void)updateKeyFrameWithRightLimit:(CGFloat) rightLimit;


@end

NS_ASSUME_NONNULL_END
