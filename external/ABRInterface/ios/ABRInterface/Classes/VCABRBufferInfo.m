//
//  ABRBufferInfo.m
//  abrmodule
//
//  Created by guikunzhi on 2020/3/29.
//  Copyright © 2020 gkz. All rights reserved.
//

#import "VCABRBufferInfo.h"

@implementation VCABRBufferInfo

- (NSString *)getStreamId {
    return _streamId;
}

- (float)getPlayerAvailDuration {
    return _playerAvailDuration;
}

- (int64_t)getFileAvailSize {
    return _fileAvailSize;
}

- (int64_t)getHeadSize {
    return _headSize;
}
@end
