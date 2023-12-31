//
//  ACCStickerDefines.h
//  CameraClient
//
//  Created by liuqing on 2020/6/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, ACCStickerGestureType) {
    ACCStickerGestureTypeNone = 0,
    ACCStickerGestureTypeTap = 1 << 0,
    ACCStickerGestureTypePan = 1 << 2,
    ACCStickerGestureTypePinch = 1 << 3,
    ACCStickerGestureTypeRotate = 1 << 4
};

NS_ASSUME_NONNULL_END
