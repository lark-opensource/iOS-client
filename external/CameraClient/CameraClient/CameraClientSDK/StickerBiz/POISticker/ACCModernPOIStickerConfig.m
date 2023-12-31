//
//  ACCModernPOIStickerConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2020/10/21.
//

#import "ACCModernPOIStickerConfig.h"
#import <CreativeKit/ACCMacros.h>
#import "AWEEditStickerHintView.h"
#import "ACCConfigKeyDefines.h"

@implementation ACCModernPOIStickerConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.preferredContainerFeature = ACCStickerContainerFeatureAdsorbing | ACCStickerContainerFeatureAngleAdsorbing | ACCStickerContainerFeatureHighlightMoment;
        
        self.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id _Nullable contextId, UIGestureRecognizer *gestureRecognizer) {
            return contextId ? NO : YES;
        };
    }
    return self;
}

- (NSArray<ACCStickerBubbleConfig *> *)bubbleActionList
{
    if (ACCConfigInt(kConfigInt_multi_poi_sticker_style) <= 1) {
        ACCStickerBubbleConfig *config = [[ACCStickerBubbleConfig alloc] init];
        config.actionType = ACCStickerBubbleActionBizEdit;
        @weakify(self);
        config.callback = ^(ACCStickerBubbleAction actionType) {
            if (actionType == ACCStickerBubbleActionBizEdit) {
                @strongify(self);
                if (self.editPOI) {
                    self.editPOI();
                }
                [AWEEditStickerHintView setNoNeedShowForType:AWEEditStickerHintTypeInteractive];
            }
        };
        return @[config];
    } else {
        return @[];
    }
}

@end
