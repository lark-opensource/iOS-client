//
//  DVEMediaContext+StickerOperation.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/13.
//

#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMediaContext (StickerOperation)

- (void)trimSticker:(NSString *)slotId targetStartTime:(CMTime)targetStartTime;

- (void)trimSticker:(NSString *)slotId duration:(CMTime)duration;

@end

NS_ASSUME_NONNULL_END
