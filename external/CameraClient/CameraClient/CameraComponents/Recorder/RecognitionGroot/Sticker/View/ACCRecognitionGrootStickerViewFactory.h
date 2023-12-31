//
//  ACCRecognitionGrootStickerViewFactory.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/23.
//

#import <Foundation/Foundation.h>
#import "ACCRecognitionGrootStickerView.h"

typedef NS_ENUM(NSUInteger, ACCRecognitionStickerViewType) {
    ACCRecognitionStickerViewNone  = 0,
    ACCRecognitionStickerViewTypeA = 1,     // 左到右：头像，标题，箭头，无描述
    ACCRecognitionStickerViewTypeB = 2,     // 上到下：标题，英文标题，描述
    ACCRecognitionStickerViewTypeC = 3,     // 纯标题
    ACCRecognitionStickerViewTypeD = 4,     // 左到右：头像 【上到下：标题，描述】
};

@interface ACCRecognitionGrootStickerViewFactory : NSObject

+ (ACCRecognitionGrootStickerView *)viewWithType:(ACCRecognitionStickerViewType)viewType;

@end

