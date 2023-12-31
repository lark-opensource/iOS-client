//
//   DVELiteTrackController.h
//   DVETrackKit
//
//   Created  by ByteDance on 2022/1/14.
//   Copyright © 2022 ByteDance Ltd. All rights reserved.
//
    

#import <Foundation/Foundation.h>
#import "DVEMediaContext.h"
#import "DVEMultipleTrackViewModel.h"
#import "DVEVideoTrackPreviewView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVELiteTrackController : NSObject

@property (nonatomic, weak) id<DVEVideoTrackPreviewDelegate> delegate;

- (instancetype)initWithContext:(DVEMediaContext *)context parentView:(UIView*)parentView;
/// 设置轨道类型
- (void)setupTrackModel:(DVEMultipleTrackType)type;
/// 刷新缩率图
- (void)refreshUI;
/// 强制布局子控件
- (void)layoutSubviews;

///当前TrackType总时长
- (CGFloat)duration;


@end

NS_ASSUME_NONNULL_END
