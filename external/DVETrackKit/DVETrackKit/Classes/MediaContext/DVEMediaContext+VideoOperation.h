//
//  DVEMediaContext+VideoOperation.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/13.
//

#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMediaContext (VideoOperation)

- (void)moveVideoSlot:(NSString *)slotId
                track:(NLETrack_OC * _Nullable)track
      targetStartTime:(CMTime)targetTimeStart
        commit:(BOOL)commit;

- (void)trimVideo:(NSString *)slotId startTime:(CMTime)start commit:(BOOL)commit;

- (void)trimVideo:(NSString *)slotId duration:(CMTime)duration commit:(BOOL)commit;

@end

NS_ASSUME_NONNULL_END
