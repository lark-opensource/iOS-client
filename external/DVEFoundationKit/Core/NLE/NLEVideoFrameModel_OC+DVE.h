//
//  NLEVideoFrameModel_OC+DVE.h
//  DVETrackKit
//
//  Created by bytedance on 2021/7/7.
//

#import <NLEPlatform/NLEVideoFrameModel+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEVideoFrameModel_OC (DVE)

/// 根据track类型获取coverModel内对应轨道的最大layer
- (NSInteger)dve_getMaxTrackLayer:(NLETrackType)type;

///根据slot的name获取coverModel内对应的slot
- (nullable NLETrackSlot_OC *)dve_slotOf:(NSString *)nodeId;

/// 获取coverModel内对应trackType的所有轨道
- (nullable NSArray<NLETrack_OC *> *)dve_allTracksOfType:(NLETrackType)type;

/// 根据slot的ids数组，删除对应trackType的轨道内id所对应的slot
- (NSArray<NLETrackSlot_OC *> *)dve_removeSlots:(NSArray<NSString *> *)ids
                                    inTrackType:(NLETrackType)trackType;

//获取coverModel内含有slotID对应slot的轨道
- (NLETrack_OC * _Nullable)dve_coverTrackContainSlotId:(NSString *)slotID;

@end

NS_ASSUME_NONNULL_END
