//
//  DVEMediaContext+Operation.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/13.
//

#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMediaContext (Operation)

- (void)moveAttachSlot:(NSString *)slotId
         insertSection:(NSInteger)insertSection
       targetStartTime:(CMTime)targetStartTime;

- (void)moveStickerSlot:(NLETrackSlot_OC *)slot
          insertSection:(NSInteger)insertSection
        targetStartTime:(CMTime)targetStartTime
          resourceTypes:(NSArray<NSNumber *> *)resourceTypes;

@end

NS_ASSUME_NONNULL_END
