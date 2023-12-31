//
//  NLETrackUtil.h
//  NLEPlatform
//
//  Created by bytedance on 2021/1/20.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "NLESequenceNode.h"
#import "NLEDiffCalculator_OC.h"
#import "NLEResourceFinderProtocol.h"

@class HTSVideoData;

NS_ASSUME_NONNULL_BEGIN

@interface NLETrackUtil : NSObject

+ (NSString *)assetKeyForSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

+ (AVURLAsset *)assetFromSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                  inVideoData:(HTSVideoData *)veVideoData
               resourceFinder:(id<NLEResourceFinderProtocol>)resourceFinder
                     assetMap:(NSMutableDictionary*)slotAssetMap;

+ (void)removeAssetFromSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                   assetMap:(NSMutableDictionary*)slotAssetMap;

+ (std::vector<std::shared_ptr<cut::model::NLETrack>>)allTracksOfType:(cut::model::NLETrackType)trackType InModel:(std::shared_ptr<const cut::model::NLEModel>)model;

+ (std::vector<std::shared_ptr<cut::model::NLETrackSlot>>)allTrackSlotsOfType:(cut::model::NLEClassType)trackType inTrack:(std::shared_ptr<cut::model::NLETrack>)track;

+ (CMTimeRange)getSourceTimeRange:(std::shared_ptr<cut::model::NLESegment>)segment;

+ (std::shared_ptr<cut::model::NLETrack>)mainTrackOfModel:(std::shared_ptr<const cut::model::NLEModel>)model;

+ (bool)isMVTypeOfModle:(std::shared_ptr<const cut::model::NLEModel>)model;

+ (bool)isBingoTypeOfModle:(std::shared_ptr<const cut::model::NLEModel>)model;

+ (std::shared_ptr<cut::model::NLETrackSlot>)slotOfName:(std::string)slotName InModel:(std::shared_ptr<const cut::model::NLEModel>)model;

+ (NSString *)getExtraInResource:(std::shared_ptr<cut::model::NLEResourceNode>)res ForKey:(NSString *)key;

+ (UIColor *)colorFromUInt:(uint32_t)uIntColor;

+ (NSArray<NSNumber *> *)getRGBAArrayFromARGBInt:(uint32_t)color;

+ (NSArray *)stringArrayFromVector:(const std::vector<std::string> &)vector;

+ (std::shared_ptr<cut::model::NLETrackSlot>)getSlotForName:(std::string)slotName
                                  withTrackType:(cut::model::NLETrackType)trackType
                                        inModel:(std::shared_ptr<const cut::model::NLEModel>)model;

+ (std::shared_ptr<cut::model::NLETrackSlot>)getSlotForName:(std::string)slotName
                                       inTracks:(std::vector<std::shared_ptr<cut::model::NLETrack>> &)tracks;

+ (bool)checkResourceNode:(std::shared_ptr<cut::model::NLEResourceNode>)resourceNode
                 inTracks:(std::vector<std::shared_ptr<cut::model::NLETrack>> &)tracks;

// calculate correct scale for video / sticker etc.
+ (float)getScaleForSlot:(std::shared_ptr<const cut::model::NLETrackSlot>)slot
                 ofTrack:(std::shared_ptr<const cut::model::NLETrack>)track
                 inModel:(std::shared_ptr<const cut::model::NLEModel>)model
               videoSize:(CGSize)videoSize;

/// 获取slot关联的关键帧信息
/// 一个轨道上所有slot的关键帧都是平铺在 track->getKeyframeSlots()
/// 而轨道上的slot关联的关键帧保存在 slot->getKeyframesUUIDList()，这个数组是保存keyframe 的 uuid
/// @param slot std::shared_ptr<NLETrackSlot>
/// @param track std::shared_ptr<NLETrack>
+ (std::vector<std::shared_ptr<cut::model::NLETrackSlot>>)getRelativeKeyframes:(std::shared_ptr<const cut::model::NLETrackSlot>)slot
                                                           inTrack:(std::shared_ptr<const cut::model::NLETrack>)track;

+ (cut::model::NLETime)getMaxEndTimeExcludeDisableNode:(std::shared_ptr<const cut::model::NLEModel>)model;
+ (cut::model::NLETime)getMaxEndTimeForTrack:(std::shared_ptr<cut::model::NLETrack>)track;

+ (std::shared_ptr<cut::model::NLETrackSlot>)firstTrackSlotInModel:(std::shared_ptr<const cut::model::NLEModel>)model WithTrackType:(cut::model::NLETrackType)trackType resourceType:(cut::model::NLEResType)resourceType;

+ (std::vector<std::shared_ptr<cut::model::NLETrackSlot>>)trackSlotInModel:(std::shared_ptr<const cut::model::NLEModel>)model WithTrackType:(cut::model::NLETrackType)trackType resourceType:(cut::model::NLEResType)resourceType;

+ (CGSize)calculateCanvasSize:(std::shared_ptr<const cut::model::NLEModel>)model;

+ (BOOL)isIntersectBetweend:(std::shared_ptr<const cut::model::NLETimeSpaceNode>)leftSlot
                       with:(std::shared_ptr<const cut::model::NLETimeSpaceNode>)rightSlot;

+ (std::vector<std::shared_ptr<cut::model::NLEFilter>>)sortedFiltersInTrack:(std::shared_ptr<cut::model::NLETrack>)track;

/// 根据NLEModel里的最新NLETrack数据，来更新changeInfos里的newNode，类型是NLETrack。
/// 目前NLE 内部有大量异步操作，如果外部没等上一次返回就commit，可能会造成数据错乱，不同步
/// @param changeInfos std::vector<NodeChangeInfo> &
/// @param model std::shared_ptr<const cut::model::NLEModel>
+ (std::vector<NodeChangeInfo>)renewDiffTracks:(std::vector<NodeChangeInfo> &)changeInfos
                                     withModel:(std::shared_ptr<const cut::model::NLEModel>)model;

@end

NS_ASSUME_NONNULL_END
