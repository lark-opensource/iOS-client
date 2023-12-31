//
//  VCABRSpeedRecord.m
//  abrmodule
//
//  Created by guikunzhi on 2020/3/29.
//  Copyright © 2020 gkz. All rights reserved.
//

#import "VCNetworkSpeedRecord.h"

@implementation VCNetworkSpeedRecord

- (nullable NSString *)getStreamId {
    return _streamId;
}

- (int)getTrackType {
    return _trackType;
}

- (int64_t)getBytes {
    return _bytes;
}

- (int64_t)getTime {
    return _time;
}

- (int64_t)getTimestamp {
    return _timestamp;
}

- (int64_t)getRtt {
    return _rtt;
}

- (int64_t)getLastRecvDate {
    return _lastRecvDate;
}

@end
