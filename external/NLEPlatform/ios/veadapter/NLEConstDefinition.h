//
//  NLEConstDefinition.h
//  NLEPlatform
//
//  Created by bytedance on 2021/3/4.
//

#ifndef NLEConstDefinition_h
#define NLEConstDefinition_h

#define NLEStickerUserInfoSlotName @"NLEStickerUserInfoSlotName"
#define NLEOneFrameDuration 0.1
#define veMaxSmoothIndensityValue 0.8

// ve卡点流程返回code值，成功>=0,错误<0
#define kIESMMBingoResultSuccess 0

typedef NS_ENUM(NSUInteger, NLEStickerAnimationType) {
    NLEStickerAnimationTypeIn = 1,
    NLEStickerAnimationTypeOut = 2,
    NLEStickerAnimationTypeLoop = 3,
};

#endif /* NLEConstDefinition_h */
