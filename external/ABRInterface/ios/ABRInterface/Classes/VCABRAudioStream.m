//
//  ABRAudioStream.m
//  abrmodule
//
//  Created by guikunzhi on 2020/3/29.
//  Copyright © 2020 gkz. All rights reserved.
//

#import "VCABRAudioStream.h"

@implementation VCABRAudioStream

- (nullable NSString *)getStreamId {
    return _streamId;
}

- (nullable NSString *)getCodec {
    return _codec;
}

- (int)getSegmentDuration {
    return _segmentDuration;
}

- (int)getBandwidth {
    return _bandwidth;
}

- (int)getSampleRate {
    return _sampleRate;
}

@end
