//
//  ACCRecognitionGrootStickerViewFactory.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/23.
//

#import "ACCRecognitionGrootStickerViewFactory.h"
#import "ACCRecognitionGrootStickerViewA.h"
#import "ACCRecognitionGrootStickerViewB.h"
#import "ACCRecognitionGrootStickerViewC.h"
#import "ACCRecognitionGrootStickerViewD.h"

@implementation ACCRecognitionGrootStickerViewFactory

+ (ACCRecognitionGrootStickerView *)viewWithType:(ACCRecognitionStickerViewType)viewType
{
    switch (viewType) {
        case ACCRecognitionStickerViewTypeA:
            return [[ACCRecognitionGrootStickerViewA alloc] init];
        case ACCRecognitionStickerViewTypeB:
            return [[ACCRecognitionGrootStickerViewB alloc] init];
        case ACCRecognitionStickerViewTypeC:
            return [[ACCRecognitionGrootStickerViewC alloc] init];
        case ACCRecognitionStickerViewTypeD:
            return [[ACCRecognitionGrootStickerViewD alloc] init];
        default:
            return nil;
    }
}

@end
