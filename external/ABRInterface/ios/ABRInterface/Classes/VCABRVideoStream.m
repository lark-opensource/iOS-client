//
//  ABRVideoStream.m
//  abrmodule
//
//  Created by guikunzhi on 2020/3/29.
//  Copyright © 2020 gkz. All rights reserved.
//

#import "VCABRVideoStream.h"

@implementation VCABRVideoStream

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

- (int)getWidth {
    return _width;
}

- (int)getHeight {
    return _height;
}

- (int)getFrameRate {
    return _frameRate;
}

@end
