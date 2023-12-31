//
// Don't edit this file directly.
// This file is generated from TTAVPlayerItem.h.in
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "TTAVPlayerItemProtocol.h"

@interface TTAVPlayerItem : NSObject<TTAVPlayerItemProtocol>

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, readonly) TTAVPlayerItemStatus status;
@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, readonly) NSInteger loadedProgress;
@property (nonatomic, readonly, getter=isPlaybackBufferEmpty) BOOL playbackBufferEmpty;
@property (nonatomic, readonly, getter=isPlaybackLikelyToKeepUp) BOOL playbackLikelyToKeepUp;
@property (nonatomic, readonly, getter=isPlaybackBufferFull) BOOL playbackBufferFull;

- (instancetype)initWithURL:(NSURL *)url;

+ (instancetype)playerItemWithURL:(NSURL *)url;

@end
