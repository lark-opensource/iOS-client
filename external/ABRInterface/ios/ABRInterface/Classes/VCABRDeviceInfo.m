//
//  VCABRDeviceInfo.m
//  ABRInterface
//
//  Created by wangchen.sh on 2020/5/25.
//

#import "VCABRDeviceInfo.h"

@implementation VCABRDeviceInfo

- (int)getScreenWidth {
    return _screenWidth;
}

- (int)getScreenHeight {
    return _screenHeight;
}

- (int)getScreenFps {
    return _screenFps;
}

- (int)getHWDecodeMaxLength {
    return _hwdecodeMaxLength;
}

- (int)getHDRInfo {
    return _hdrInfo;
}

@end
