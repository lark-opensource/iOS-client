//
//  ACCAutoCaptionsTextStickerConfig.m
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/27.
//

#import "ACCAutoCaptionsTextStickerConfig.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCStickerBizDefines.h"

@implementation ACCAutoCaptionsTextStickerConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.preferredContainerFeature = ACCStickerContainerFeatureAutoCaptions;
        
        self.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id _Nullable contextId, UIGestureRecognizer *gestureRecognizer) {
            return gestureType != ACCStickerGestureTypeRotate;
        };
        self.maximumScale = 2;
        self.minimumScale = 0.5;
    }
    return self;
}

- (NSArray<ACCStickerBubbleConfig *> *)bubbleActionList
{
    ACCStickerBubbleConfig *eidtConfig = [[ACCStickerBubbleConfig alloc] init];
    eidtConfig.actionType = ACCStickerBubbleActionBizEditAutoCaptions;
    @weakify(self);
    eidtConfig.callback = ^(ACCStickerBubbleAction actionType) {
        if (actionType == ACCStickerBubbleActionBizEditAutoCaptions) {
            @strongify(self);
            !self.editBlock ?: self.editBlock();
        }
    };
    ACCStickerBubbleConfig *deleteConfig = [[ACCStickerBubbleConfig alloc] init];
    deleteConfig.actionType = ACCStickerBubbleActionBizDelete;
    deleteConfig.callback = ^(ACCStickerBubbleAction actionType) {
        if (actionType == ACCStickerBubbleActionBizDelete) {
            @strongify(self);
            !self.deleteBlock ?: self.deleteBlock();
        }
    };
    return @[eidtConfig, deleteConfig];
}

@end
