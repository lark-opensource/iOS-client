//
//  TTAVPlayerItemProtocol.h
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#ifndef TTM_TTPLAYER_ITEM_PROTOCOL
#define TTM_TTPLAYER_ITEM_PROTOCOL

typedef NS_ENUM(NSInteger, TTAVPlayerItemStatus) {
    TTAVPlayerItemStatusUnknown,
    TTAVPlayerItemStatusReadyToPlay,
    TTAVPlayerItemStatusReadyToRender,
    TTAVPlayerItemStatusFailed,
    TTAVPlayerItemStatusCompleted,
    TTAVPlayerItemStatusReadyForDisplay,
};

static NSString *const TTPlayerErrorHTTPHeaderKey = @"header";

@protocol TTAVPlayerItemProtocol <NSObject>

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, readonly) TTAVPlayerItemStatus status;
@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, readonly) NSInteger loadedProgress;
@property (nonatomic, readonly, getter=isPlaybackBufferEmpty) BOOL playbackBufferEmpty;
@property (nonatomic, readonly, getter=isPlaybackLikelyToKeepUp) BOOL playbackLikelyToKeepUp;
@property (nonatomic, readonly, getter=isPlaybackBufferFull) BOOL playbackBufferFull;

@end

#endif // TTM_TTPLAYER_ITEM_PROTOCOL
