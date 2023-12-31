//
//  AWEStickerPickerControllerSchemaStickerPlugin.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/24.
//

#import "AWEStickerPickerControllerSchemaStickerPlugin.h"
#import <CreativeKit/ACCRouterProtocol.h>

@implementation AWEStickerPickerControllerSchemaStickerPlugin

- (void)controller:(AWEStickerPickerController *)controller didSelectNewSticker:(IESEffectModel *)newSticker oldSticker:(IESEffectModel *)oldSticker {
    if (IESEffectModelEffectTypeSchema == newSticker.effectType) {
        if (newSticker.schema.length) {
            [ACCRouter() transferToURLStringWithFormat:@"%@", newSticker.schema];
        }
    }
}

@end
