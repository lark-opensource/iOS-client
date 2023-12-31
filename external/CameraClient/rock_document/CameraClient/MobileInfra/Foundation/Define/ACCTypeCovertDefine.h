//
//  ACCTypeCovertDefine.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/25.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ACCStickerPinStatus) {
    // 未被Pin
    ACCStickerPinStatus_None,
    // 正在Pin
    ACCStickerPinStatus_Pinning,
    // Pin成功
    ACCStickerPinStatus_Pinned,
};

