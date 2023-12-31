//
//  BDCTAudioPlayer.m
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/2/3.
//

#import "BDCTAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>


@interface BDCTAudioPlayer () <AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@property (nonatomic, copy) NSString *playingURLString;

@property (nonatomic, assign) BDCTAudioPlayerState audioPlayerState;

@property (nonatomic, copy) dispatch_block_t executationBlock;

@property (nonatomic, strong) dispatch_queue_t audioPlayerQueue;

@end


@implementation BDCTAudioPlayer

- (instancetype)init {
    self = [super init];
    if (self) {
        _audioPlayerQueue = dispatch_queue_create("com.bytedance.bytedcert.audio.play.queue", 0);
    }
    return self;
}

- (void)playAudioWithFilePath:(NSString *)path {
    if (!path)
        return;
    if ([self.playingURLString isEqualToString:path]) {
        return;
    }
    self.playingURLString = path;
    self.executationBlock = dispatch_block_create(0, ^{
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        if (!fileURL) {
            [self setAudioPlayerState:BDCTAudioPlayerStateStop];
            return;
        }
        [self playAudioWithFileURL:fileURL];
    });
    dispatch_async(_audioPlayerQueue, self.executationBlock);
}

- (void)playAudioWithFileURL:(NSURL *)fileURL {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];

    [self setAudioPlayerState:BDCTAudioPlayerStatePlaying];

    NSError *audioPlayerError;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&audioPlayerError];
    if (!_audioPlayer) {
        return;
    }

    _audioPlayer.volume = 1.0f;
    _audioPlayer.delegate = self;
    [_audioPlayer prepareToPlay];

    [_audioPlayer play];
}

- (void)stopAudioPlayer {
    if (_audioPlayer) {
        _audioPlayer.playing ? [_audioPlayer stop] : nil;
        _audioPlayer.delegate = nil;
        _audioPlayer = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];
        [[AVAudioSession sharedInstance] setActive:NO
                                       withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                             error:nil];
    }
}

- (void)setPlayingURLString:(NSString *)playingURLString {
    if (playingURLString) {
        if (self.executationBlock) {
            dispatch_block_cancel(self.executationBlock);
        }
        [self stopAudioPlayer];
    }
    _playingURLString = [playingURLString copy];
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self setAudioPlayerState:BDCTAudioPlayerStateStop];
}

@end
