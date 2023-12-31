//
//  TTMovieView.m
//  testAVPlayer
//
//  Created by Chen Hong on 15/10/11.
//
//

#import "TTVideoEngineMoviePlayerLayerView.h"

#import <AVFoundation/AVFoundation.h>

@implementation TTVideoEngineMoviePlayerLayerView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer
{
    return (AVPlayerLayer *)self.layer;
}

- (void)setPlayer:(AVPlayer*)player
{
    [(AVPlayerLayer*)[self layer] setPlayer:player];
}


@end
