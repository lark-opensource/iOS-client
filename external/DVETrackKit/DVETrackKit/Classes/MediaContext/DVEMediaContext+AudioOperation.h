//
//  DVEMediaContext+AudioOperation.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/13.
//

#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMediaContext (AudioOperation)

// MARK: 裁剪音频左侧
- (void)trimAudio:(NSString *)slotId targetStartTime:(CMTime)targetStartTime;

// MARK: 裁剪音频右侧
- (void)trimAudio:(NSString *)slotId duration:(CMTime)duration;

@end

NS_ASSUME_NONNULL_END
