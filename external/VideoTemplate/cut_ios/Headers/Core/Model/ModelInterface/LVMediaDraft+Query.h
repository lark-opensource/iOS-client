//
//  LVMediaDraft+Query.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/12.
//

#import "LVMediaDraft.h"
#import "LVMediaDefinition.h"
#import "LVModelType.h"
#import "LVMediaDraftHeaders.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVMediaDraft (Query)

/**
 视频主轨
 */
- (LVMediaTrack * _Nullable)mainVideoTrack;

/**
 查询所有满足条件的轨道
 @param type 轨道类型
*/
- (NSArray<LVMediaTrack *>*)allTracksOfType:(LVMediaTrackType)type;

/**
 查询所有满足条件的轨道
 @param type 轨道类型
 @param flag 轨道特征
*/
- (NSArray<LVMediaTrack *> *)tracksOfType:(LVMediaTrackType)type flag:(LVMediaTrackFlag)flag;

- (NSArray<LVMediaSegment *> * _Nullable)segmentsWithTrackType:(LVMediaTrackType)trackType;

- (NSArray<LVMediaSegment *> * _Nullable)segmentsWithTrackType:(LVMediaTrackType)trackType
                                                   segmentType:(LVPayloadRealType)segmentType;

- (NSArray<LVDraftPayload *> *)totalPayloads;

- (LVMediaSegment * _Nullable)segmentWithPayloadID:(NSString *)payloadId
                                       trackType:(LVMediaTrackType)trackType;

- (LVMediaSegment * _Nullable)segmentWithSegmentID:(NSString *)segmentID
                                         trackType:(LVMediaTrackType)trackType;

- (LVDraftPayload * _Nullable)payloadWithPayloadID:(NSString *)payloadId
                                           segment:(LVMediaSegment *)segment;

- (LVDraftPayload * _Nullable)payloadWithPayloadID:(NSString *)payloadId
                                         trackType:(LVMediaTrackType)trackType;
@end


@interface LVMediaDraft (Tracker)

- (void)appendEditType:(NSString *)editType;

@property (nonatomic, copy, readonly, nullable) NSString *editTypeString;

@end

NS_ASSUME_NONNULL_END
