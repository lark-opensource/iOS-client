//
//   DVELiteTimelineContentView.h
//   DVETrackKit
//
//   Created  by ByteDance on 2022/1/14.
//   Copyright © 2022 ByteDance Ltd. All rights reserved.
//
    

#import <UIKit/UIKit.h>
#import "DVEMediaContext.h"
#import "DVEVideoTrackPreviewView.h"
#import "DVEMultipleTrackView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVELiteTimelineContentView : UIView

/// 上下文
@property (nonatomic, strong) DVEMediaContext *context;
/// 轨道手势代理
@property (nonatomic, weak) id<DVEVideoTrackPreviewDelegate> delegate;

- (instancetype)initWithContext:(DVEMediaContext *)context;

/// 设置轨道类型
/// @param type 轨道类型
- (void)setupTrackType:(DVEMultipleTrackType)type;

/// 时长
- (CGFloat)duration;
@end

NS_ASSUME_NONNULL_END
