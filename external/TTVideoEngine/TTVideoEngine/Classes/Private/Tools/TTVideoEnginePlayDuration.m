//
//  TTVideoEnginePlayDuration.m
//  ABRInterface
//
//  Created by bytedance on 2022/3/10.
//

#import "TTVideoEnginePlayDuration.h"

@implementation TTVideoEnginePlayDuration

- (instancetype)init {
    if (self = [super init]) {
        _state = PlayDurationStateStop;
        _playedDuration = 0;
        _startPlayTime = 0;
    }
    return self;
}

- (void)start {
    if (_state == PlayDurationStateStop) {
        _state = PlayDurationStatePlaying;
        _startPlayTime = CACurrentMediaTime();
    }
}

- (void)stop {
    if (_state == PlayDurationStatePlaying) {
        _state = PlayDurationStateStop;
        NSTimeInterval duration = CACurrentMediaTime() - _startPlayTime;
        if (duration >= 0) {
            _playedDuration += duration;
        }
    }
}

- (NSTimeInterval) getPlayedDuration {
    if (_state == PlayDurationStatePlaying) {
        NSTimeInterval curTime = CACurrentMediaTime();
        NSTimeInterval duration = curTime - _startPlayTime;
        if (duration >= 0) {
            _playedDuration += duration;
        }
        _startPlayTime = curTime;
    }
    return _playedDuration;
}

- (void) clear {
    _playedDuration = 0;
    if (_state == PlayDurationStatePlaying) {
        _startPlayTime = CACurrentMediaTime();
    }
}

- (void) reset {
    _state = PlayDurationStateStop;
    _playedDuration = 0;
    _startPlayTime = 0;
}

@end
