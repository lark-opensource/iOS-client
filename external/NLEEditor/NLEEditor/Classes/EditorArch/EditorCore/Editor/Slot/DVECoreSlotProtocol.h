//
//  DVECoreSlotProtocol.h
//  NLEEditor
//
//  Created by bytedance on 2021/8/6.
//

#import <NLEPlatform/NLETrackSlot+iOS.h>
#import "DVECoreProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVECoreSlotProtocol <DVECoreProtocol>

- (NLETrackSlot_OC *)splitForSlot:(NLETrackSlot_OC *)slot;

- (NLETrackSlot_OC *)copyForSlot:(NSString *)segmentId needCommit:(BOOL)commit;

- (BOOL)removeSlot:(NSString *)segmentId
        needCommit:(BOOL)commit;

- (NLETrackSlot_OC *)addSlot:(NLETrackType)trackType
                resourceType:(NLEResourceType)resourceType
                     segment:(NLESegment_OC *)segment
                   startTime:(CMTime)startTime
                    duration:(CMTime)duration;

@end

NS_ASSUME_NONNULL_END

