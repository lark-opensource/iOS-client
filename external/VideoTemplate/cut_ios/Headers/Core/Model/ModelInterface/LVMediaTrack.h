//
//  LVMediaTrack.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LVMediaDraft.h"
#import "LVMediaSegment.h"
#import "LVMediaDefinition.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVMediaTrack (Interface)<LVCopying>
///**
// 轨道ID
// */
//@property(nonatomic, copy) NSString *trackID;

/**
 轨道类型
 */
@property(nonatomic, assign) LVMediaTrackType type;

///**
// 轨道包含的片段
// */
//@property(nonatomic, copy) NSArray<LVMediaSegment *>*segments;

/**
 二进制第0位标识是否原始字幕轨道、视频是否是主轨道
 */
@property(nonatomic, assign) LVMediaTrackFlag flag;

/**
 轨道最长时长
 */
@property(nonatomic, assign, readonly) CMTime duration;

/**
 初始化轨道
 
 @param type 轨道类型
 @return 轨道
 */
- (instancetype)initWithType:(LVMediaTrackType)type;

/**
 初始化轨道
 
 @param type 轨道类型
 @param trackID 轨道ID
 @return 轨道
 */
- (instancetype)initWithType:(LVMediaTrackType)type trackID:(NSString  * _Nullable)trackID;

/**
 插入片段
 
 @param segment 片段
 @param targetStartTime 目标时间轴
 */
- (void)insertSegment:(LVMediaSegment *)segment at:(CMTime)targetStartTime;


/**
 插入片段
 
 @param segment 片段
 @param targetStartTime 目标时间轴
 @param sorted 是否按照时间轴时间排序
 */
- (void)insertSegment:(LVMediaSegment *)segment
                   at:(CMTime)targetStartTime
               sorted:(BOOL)sorted;

/**
 第一个片段
 
 @return 片段
 */
- (LVMediaSegment * _Nullable)firstSegment;

/**
 调整内部片段
 */
- (void)adjustTrackTargetStartTime;

/**
 片段重组排序
 */
- (void)sort;

@end

NS_ASSUME_NONNULL_END
