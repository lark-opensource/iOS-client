//
//  DVETimelineGlobal.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVETimelineGlobal : NSObject

@property (nonatomic, assign, readonly, class) CGFloat timelineOffsetX;

// 时间线区域高度
@property (nonatomic, assign, readonly, class) CGFloat containerHeight;

// 轨道之间间距
@property (nonatomic, assign, readonly, class) CGFloat lineSpace;

// 非主轨道高度
@property (nonatomic, assign, readonly, class) CGFloat lineHeight;

// 视频轨道到顶部距离
@property (nonatomic, assign, readonly, class) CGFloat videoToTop;

// 视频轨道到顶部距离，打开多轨的情况
@property (nonatomic, assign, readonly, class) CGFloat videoToTopWithMuti;


// 可视线高度
@property (nonatomic, assign, readonly, class) CGFloat exlineHeight;

// 可视线间距
@property (nonatomic, assign, readonly, class) CGFloat exlineSpace;

// 可视线距离轨道的间距
@property (nonatomic, assign, readonly, class) CGFloat exlineSpaceToTrack;


@property (nonatomic, assign, readonly, class) CGFloat controlBarHeight;

@end

NS_ASSUME_NONNULL_END
