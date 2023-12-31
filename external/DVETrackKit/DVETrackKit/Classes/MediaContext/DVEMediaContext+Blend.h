//
//  DVEMediaContext+Blend.h
//  NLEPlatform
//
//  Created by bytedance on 2021/4/14.
//

#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMediaContext (Blend)

- (void)trimBlend:(NSString *)slotId targetStartTime:(CMTime)targetStartTime;

- (void)trimBlend:(NSString *)slotId duration:(CMTime)duration;

- (void)moveBlendSlot:(NSString *)slotId
        insertSection:(NSInteger)insertSection
      targetStartTime:(CMTime)targetStartTime;

@end

NS_ASSUME_NONNULL_END
