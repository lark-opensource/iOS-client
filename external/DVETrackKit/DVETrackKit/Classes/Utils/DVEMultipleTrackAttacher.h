//
//  DVEMultipleTrackAttacher.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/17.
//

#import "DVEAttacher.h"
#import <NLEPlatform/NLEModel+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVEMultipleTrackAttacherDelegate <NSObject>

- (CMTime)timeLinePointToTime;

@end

@interface DVEMultipleTrackAttacher : DVEAttacher

@property (nonatomic, assign) NLETrackType trackType;

// 这里需要使用UI上的时间，实际的context.currentTime与UI时间可能存在1帧的时间差
@property (nonatomic, weak) id<DVEMultipleTrackAttacherDelegate> delegate;
@property (nonatomic, strong, nullable) NLETimeSpaceNode_OC *selectedNode;

@end

NS_ASSUME_NONNULL_END
