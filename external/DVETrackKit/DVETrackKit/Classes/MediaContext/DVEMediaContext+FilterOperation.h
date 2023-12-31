//
//  DVEMediaContext+FilterOperation.h
//  DVETrackKit
//
//  Created by bytedance on 2021/8/11.
//

#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMediaContext (FilterOperation)

- (void)trimFilter:(NSString *)slotId targetStartTime:(CMTime)targetStartTime;
- (void)trimFilter:(NSString *)slotId duration:(CMTime)duration;

@end

NS_ASSUME_NONNULL_END
